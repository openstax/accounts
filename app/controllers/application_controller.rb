class ApplicationController < ActionController::Base
  use_openstax_exception_rescue

  include Lev::HandleWith

  respond_to :html

  layout 'application_body_only'

  skip_before_filter :authenticate_user!, only: [:routing_error]

  def routing_error
    raise ActionController::RoutingError.new(params[:path])
  end
end
