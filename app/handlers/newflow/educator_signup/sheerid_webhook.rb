module Newflow
  module EducatorSignup
    class SheeridWebhook
      lev_handler
      uses_routine ProcessSheeridWebhookRequest

      protected ###############

      VERIFICATION_ID_PARAM_NAME = 'verificationId' # the param that SheerID sends us

      def authorized?
        true
      end

      def handle
        Rails.logger.info("bryan_sheerid_verify. request came in from SheerID. params: #{params.inspect}; IP: #{request.ip}")
        verification_id = params.fetch(VERIFICATION_ID_PARAM_NAME)
        outputs.verification_id = verification_id
        run(ProcessSheeridWebhookRequest, verification_id: verification_id)
      end
    end
  end
end
