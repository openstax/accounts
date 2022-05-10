class ApplicationController < ActionController::Base

  include AuthenticateMethods

  layout 'application'

  before_action :authenticate_user!
  fine_print_skip :general_terms_of_use, :privacy_policy

  def check_if_admin
    # used in blazer.yml to check if user is authorized for Blazer
    return true if !Rails.env.production?
    authenticate_admin! unless current_user&.is_administrator?
  end

  def return_url_specified_and_allowed?
    # This returns true if `save_redirect` actually saved the URL
    params[:r] && params[:r] == stored_url
  end

  include Lev::HandleWith

  respond_to :html
end
