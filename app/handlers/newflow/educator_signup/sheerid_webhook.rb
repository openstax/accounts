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
        verification_id = params.fetch(VERIFICATION_ID_PARAM_NAME)
        outputs.verification_id = verification_id
        run(ProcessSheeridWebhookRequest, verification_id: verification_id)
      end
    end
  end
end
