module Newflow
  module EducatorSignup
    # Verify their Educator status given their (SheerID) Verification ID.
    # Expects a user to already exist with that SheerID Verification ID.
    class VerifyEducator

      lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }

      uses_routine UpsertSheeridVerification

      protected ###############

      def exec(verification_id:, user:)
        status.set_job_name(self.class.name)
        status.set_job_args(verification_id: verification_id.to_s, user: user.to_global_id.to_s)

        verification_record = fetch_verification(verification_id)
        transfer_errors_from(verification_record, {type: :verbatim}, :fail_if_errors)
        return if !verification_record.verified?

        # If the user is already faculty verified, nothing to do.
        return if user.confirmed_faculty?

        email = EmailAddress.verified.find_by(value: verification_record.email)

        capture_mismatch_error!(verification_id, email, user) and return if email_mismatch?(user, email)

        if update_user(user, verification_record)
          log_success(verification_id, user)
        else
          handle_error(verification_id, user)
        end
      end

      private #################

      def update_user(user, verification)
        first_update = user.update(
          first_name: verification.first_name,
          last_name: verification.last_name,
          sheerid_reported_school: verification.organization_name,
          sheerid_verification_id: verification.verification_id,
          is_sheerid_verified: verification.verified?,
          # update role in case the user signed up as a student but then requested faculty verification and got approved.
          role: (user.role == User::STUDENT_ROLE ? User::INSTRUCTOR_ROLE : user.role)
        )

        if first_update && user.is_sheerid_verified? && user.is_profile_complete?
          user.update(faculty_status: User::CONFIRMED_FACULTY)
          SecurityLog.create!(
            user: user,
            event_type: :user_updated_using_sheerid_data,
            message: "Educator verified by SheerID."
          )
        else
          first_update
          SecurityLog.create!(
            user: user,
            event_type: :user_updated_using_sheerid_data,
            event_data: { updated_data: first_update }
          )
        end
      end

      def fetch_verification(verification_id)
        @fetch_verification ||= run(UpsertSheeridVerification, verification_id: verification_id).outputs.verification
      end

      def email_mismatch?(user, email)
        user.blank? || email.blank? || email.user_id != user.id
      end

      def capture_mismatch_error!(verification_id, email, user)
        message = 'verification id and email mismatch'

        Sentry.capture_message(
          message,
          extra: {
            verification_id: verification_id,
            email_id: email&.id,
            user_id: user&.id
          }
        )
        nonfatal_error(code: :email_mismatch, message: message)
      end

      def log_success(verification_id, user)
        SecurityLog.create!(
          user: user,
          event_type: :educator_verified_using_sheerid
        )
      end

      def handle_error(verification_id, user)
        message =  "User (#{user.id}) verification_id (#{verification_id}); User errors (#{user.errors&.full_messages})"
        Rails.logger.warn(message)
        SecurityLog.create!(
          user: user,
          event_type: :educator_sign_up_failed,
          event_data: { error: message }
        )
        fatal_error(code: :error_updating_user, message: message)
      end

    end
  end
end
