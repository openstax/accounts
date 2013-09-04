module Api
  module V1
    class OauthBasedApiController < ApiController      

      respond_to :json

      def current_user
        @current_user ||= doorkeeper_token ? 
                          User.where(id: doorkeeper_token.resource_owner_id).first || AnonymousUser.instance : 
                          AnonymousUser.instance
      end
         
    end
  end
end