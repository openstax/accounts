module Api
  module V1
    class KeyBasedApiController < ApiController      
      
      before_filter :restrict_access
      
    protected

      attr_reader :current_application

      def restrict_access
        authenticate_or_request_with_http_token do |token, options|
          @current_application = Doorkeeper::Application.where{secret == token}.first
          !@current_application.nil?
        end
      end

    end
   
  end
end