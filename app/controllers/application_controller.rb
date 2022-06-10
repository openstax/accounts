class ApplicationController < ActionController::Base
  layout 'application'

  before_action :authenticate_user!
  before_action :return_url_specified_and_allowed?
  before_action :check_if_password_expired

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :disable_fine_print

  def disable_fine_print
    request.options? ||
    contracts_not_required ||
    current_user.is_anonymous?
  end

  def check_if_password_expired
    return true if request.format != :html || request.options?

    identity = current_user.identity
    return unless identity.try(:password_expired?)

    flash[:alert] = I18n.t(:"controllers.identities.password_expired")
    redirect_to(password_reset_path)
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

  def allow_iframe_access
    @iframe_parent = params[:parent]

    if @iframe_parent.blank?
      response.headers.except! 'X-Frame-Options'
      return true
    end

    if Host.trusted? @iframe_parent
      response.headers.except! 'X-Frame-Options'
    else
      raise SecurityTransgression.new("#{@iframe_parent} is not allowed to iframe content")
    end
    true
  end
end
