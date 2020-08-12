module Newflow
  module EducatorSignup
    # When a POST request comes in from SheerID, we:
    # save the verification id  and
    class ProcessSheeridWebhookRequest

      lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }
      uses_routine UpsertSheeridVerification
      uses_routine SheeridRejectedEducator

      protected ###############

      def exec(verification_id:)
        status.set_job_name(self.class.name)
        status.set_job_args(verification_id: verification_id)

        verification_details = SheeridAPI.get_verification_details(verification_id)
        fatal_error(code: :sheerid_api_call_failed) if !verification_details.success?

        verification = upsert_verification(verification_id, verification_details)
        existing_user = EmailAddress.verified.find_by(value: verification.email)&.user

        if !existing_user.present?
          Rails.logger.warn(
            "[ProcessSheeridWebhookRequest] No user found with verification id #{verification_id} "\
            "and email #{verification.email}"
          )
          return
        end

        if verification.errors.none? && verification.verified?
          VerifyEducator.perform_later(verification_id: verification_id, user: existing_user)
        elsif verification.rejected?
          run(SheeridRejectedEducator, user: existing_user, verification_id: verification_id)
        elsif verification.present?.present?
          existing_user.sheerid_verification_id = verification_id if existing_user.sheerid_verification_id.blank?

          if verification_details.relevant?
            existing_user.first_name = verification.first_name
            existing_user.last_name = verification.last_name
            existing_user.sheerid_reported_school = verification.organization_name
            existing_user.faculty_status = verification.current_step_to_faculty_status
          end

          if existing_user.changed?
            existing_user.save
            transfer_errors_from(existing_user, {type: :verbatim}, :fail_if_errors)
            SecurityLog.create!(
              user: existing_user,
              event_type: :user_updated_using_sheerid_data,
              event_data: { verification: verification.inspect }
            )
          end
        end

        outputs.verification = verification
      end

      private #################

      def upsert_verification(verification_id, details)
        @verification ||= run(UpsertSheeridVerification,
          verification_id: verification_id,
          details: details
        ).outputs.verification
      end

    end
  end
end
