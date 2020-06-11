module Newflow
  class SheeridWebhook
    lev_handler

    protected ###############

    def authorized?
      SHEERID_IP_WHITELIST.include?(request.remote_ip)
    end

    def handle
      verification_id = params['verificationId']
      UpdateUserFromSheeridWebhook.perform_later(verification_id: verification_id)
    end
  end
end
