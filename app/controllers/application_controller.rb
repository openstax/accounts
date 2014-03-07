class ApplicationController < ActionController::Base
  protect_from_forgery

  include Lev::HandleWith

  before_filter :authenticate_user!

  fine_print_get_signatures :general_terms_of_use,
                            :privacy_policy

  layout 'application_body_only'

protected

  # These methods are defined in the base class via the 02... initializer
  helper_method :current_user, :current_user=, :signed_in?, :sign_in, :sign_out!

  def authenticate_user!
    redirect_to login_path, notice: "Please log in." unless signed_in?
  end

end