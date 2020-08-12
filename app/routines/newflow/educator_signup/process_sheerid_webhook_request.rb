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
        return if !verification_details.relevant?

        verification = upsert_verification(verification_id, verification_details)
        existing_user = EmailAddress.verified.find_by(value: verification.email)&.user

        if verification.errors.none? && verification.verified? && existing_user
          VerifyEducator.perform_later(verification_id: verification_id, user: existing_user)
        elsif verification.rejected? && existing_user
          run(SheeridRejectedEducator, user: existing_user, verification_id: verification_id)
        elsif verification.present? && existing_user.present?
          existing_user.faculty_status = verification.current_step_to_faculty_status
          existing_user.sheerid_verification_id = verification_id if existing_user.sheerid_verification_id.blank?
          existing_user.save
          transfer_errors_from(existing_user, {type: :verbatim}, :fail_if_errors)
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
