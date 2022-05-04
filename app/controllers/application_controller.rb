class ApplicationController < ActionController::Base

  include ApplicationHelper

  layout 'application'

  def check_if_admin
    #return true if !Rails.env.production?
    return authenticate_admin! unless current_user && current_user.is_administrator?
  end

  def return_url_specified_and_allowed?
    # This returns true if `save_redirect` actually saved the URL
    params[:r] && params[:r] == stored_url
  end

  include Lev::HandleWith

  respond_to :html
end
