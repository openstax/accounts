class ApplicationController < ActionController::Base

  layout 'application'

  before_action :authenticate_user!
  before_action :return_url_specified_and_allowed?
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

  protected

  def redirect_instructors_needing_to_complete_signup
    return unless current_user.instructor?

    unless current_user.is_sheerid_unviable? || current_user.is_profile_complete?
      security_log(:educator_resumed_signup_flow, message: 'User needs to complete SheerID verification.')
      redirect_to sheerid_form_path and return
    end

    if current_user.is_needs_profile? || !current_user.is_profile_complete?
      security_log(:educator_resumed_signup_flow, message: 'User has not completed profile.')
      redirect_to profile_form_path and return
    end
  end

  def redirect_back_if_allowed
    redirect_param = params[:r]
    if redirect_param && Host.trusted?(redirect_param)
      redirect_to redirect_param
    end
  end
end
