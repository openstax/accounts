class ApplicationController < ActionController::Base
  protect_from_forgery

protected

  # These methods are defined in the base class via the 02... initializer
  helper_method :current_user, :current_user=, :signed_in?

end

