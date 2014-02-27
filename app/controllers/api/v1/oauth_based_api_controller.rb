module Api
  module V1
    class OauthBasedApiController < ApiController      

      respond_to :json

      def current_user
        @current_api_user ||= ApiUser.new(doorkeeper_token, lambda { super })
      end
         
    end
  end
end