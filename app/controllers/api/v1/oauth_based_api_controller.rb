module Api
  module V1
    class OauthBasedApiController < ApiController      

      respond_to :json
      
    protected

      def current_user
        @current_user ||= doorkeeper_token ? 
                          User.find(doorkeeper_token.resource_owner_id) : 
                          AnonymousUser.instance
      end
   
    end
  end
end