module Newflow
  module EducatorSignup
  # Verify their Educator status given their (SheerID) Verification ID
  # Expects a user to already exist with that SheerID Verification ID
    class VerifyEducator
      lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }, use_jobba: true
      uses_routine UpsertSheeridVerification
      uses_routine UpdateSalesforceLead

      protected ###############

      def exec(verification_id:, user:)
        status.set_job_name(self.class.name)
        status.set_job_args(verification_id: verification_id.to_s, user: user.to_global_id.to_s)

        verification_record = fetch_verification(verification_id)
        transfer_errors_from(verification_record, {type: :verbatim}, :fail_if_errors)
        return if !verification_record.verified?

        # If the user is already faculty verified, nothing to do. If they're a student, don't faculty verify.
        return if user.confirmed_faculty? || user.student?

        email = EmailAddress.verified.find_by(value: verification_record.email)

        capture_mismatch_error!(verification_id, email, user) and return if email_mismatch?(user, email)

        if update_user(user, verification_record) && update_salesforce_lead_for(user)
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
        )

        if first_update && user.is_sheerid_verified? && user.is_profile_complete?
          user.update(faculty_status: User::CONFIRMED_FACULTY)
        else
          first_update
        end
      end

      def fetch_verification(verification_id)
        @fetch_verification ||= run(UpsertSheeridVerification, verification_id: verification_id).outputs.verification
      end

      def update_salesforce_lead_for(user)
        run(UpdateSalesforceLead, user: user).outputs.lead.errors.none?
      end

      def email_mismatch?(user, email)
        user.blank? || email.blank? || email.user_id != user.id
      end

      def capture_mismatch_error!(verification_id, email, user)
        message = 'verification id and email mismatch'

        Raven.capture_message(
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
        lead_id = user.salesforce_lead_id

        SecurityLog.create!(
          user: user,
          event_type: :educator_verified_using_sheerid,
          event_data: { verification_id: verification_id, lead_id: lead_id }
        )
      end

      def handle_error(verification_id, user)
          "User (#{user.id}) verification_id (#{verification_id}); User errors (#{user.errors.full_messages})"

          Rails.logger.warn(message)
        fatal_error(code: :error_updating_user, message: message)
      end
    end
  end
end
