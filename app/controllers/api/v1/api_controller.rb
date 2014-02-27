module Api
  module V1
    class ApiController < ApplicationController           
      
      skip_before_filter :authenticate_user!
      respond_to :json
      rescue_from Exception, :with => :rescue_from_exception
      
    protected

      def rescue_from_exception(exception)
        # See https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L453 for error names/symbols
        error = :internal_server_error
    
        case exception
        when SecurityTransgression
          error = :forbidden
        when ActiveRecord::RecordNotFound, 
             ActionController::RoutingError,
             ActionController::UnknownController,
             AbstractController::ActionNotFound
          error = :not_found
        end

        head error
      end

    end

   
  end
end