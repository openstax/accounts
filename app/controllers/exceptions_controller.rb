class ExceptionsController < ApplicationController

  def rescue_from
    # render 500 error page
    @exception = request.env["action_dispatch.exception"]

    OpenStax::RescueFrom.perform_rescue @exception, self
  end

  def missing_route
    # render 404 error page
    @exception = ActionController::RoutingError.new(
      "No route matches [#{request.env['REQUEST_METHOD']}] #{request.env['PATH_INFO'].inspect}"
    )

    OpenStax::RescueFrom.perform_rescue @exception, self
  end
end
