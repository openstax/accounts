module Api
  module V1
    class OauthBasedApiController < ApiController      

      respond_to :json

      def current_user
        @current_user ||= ApiUser.new(doorkeeper_token, lamda { super })
      end
         
    end
  end
end