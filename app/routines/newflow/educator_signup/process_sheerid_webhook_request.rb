module Newflow
  module EducatorSignup
    # When a POST request comes in from SheerID, we:
    # save the verification id  and
    class ProcessSheeridWebhookRequest
      lev_routine
      uses_routine UpsertSheeridVerification
      uses_routine SheeridRejectedEducator

      protected ###############

      def exec(verification_id:)
        status.set_job_name(self.class.name)
        status.set_job_args(verification_id: verification_id)

        verification = upsert_verification(verification_id)
        if verification.errors.none? && verification.verified? && (user = EmailAddress.verified.find_by(value: verification.email)&.user)
          VerifyEducator.perform_later(verification_id: verification&.verification_id, user: user)
        elsif verification.errors.present?
          Rails.logger.warn("#{self.class.name} ERROR! verification.errors.full_messages")
        elsif verification.rejected? && (user = EmailAddress.verified.find_by(value: verification.email)&.user)
          run(SheeridRejectedEducator, user: user)
        end

        outputs.verification = verification
      end

      private #################

      def upsert_verification(verification_id)
        @verification ||= run(UpsertSheeridVerification, verification_id: verification_id).outputs.verification
      end
    end
  end
end
