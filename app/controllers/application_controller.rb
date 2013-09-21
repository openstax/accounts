class ApplicationController < ActionController::Base
  protect_from_forgery

  include Lev::HandleWith

  layout 'application_body_only'

protected

  # These methods are defined in the base class via the 02... initializer
  helper_method :current_user, :current_user=, :signed_in?, :sign_in, :sign_out!

end

