class ApplicationController < ActionController::Base
  layout 'application'

  before_action :authenticate_user!
  before_action :check_if_password_expired

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :disable_fine_print

  def disable_fine_print
    request.options? ||
    contracts_not_required ||
    current_user.is_anonymous?
  end

  def check_if_admin
    return true if !Rails.env.production?
    is_admin?
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

  def set_unverified_user
    save_unverified_user(current_user.id)
  end

  def check_if_signup_complete
    # user has not verified email address - send them back to verify email form
    if current_user.faculty_status == 'incomplete_signup'
      redirect_to(verify_email_by_pin_form_path) and return
    end

    # If the user is not a student, let's make sure they finished the signup process.
    unless current_user.student?
      if current_user.needs_verification?
        security_log(:educator_resumed_signup_flow,
                     message: 'User needs to complete SheerID verification - return to SheerID verification form.')
        redirect_to sheerid_form_path and return
      end

      if current_user.needs_profile?
        security_log(:educator_resumed_signup_flow,
                     message: 'User has not completed profile - return to complete profile screen.')
        redirect_to profile_form_path and return
      end
    end
    redirect_back(fallback_location: profile_path)
  end

  def restart_signup_if_missing_unverified_user
    unless unverified_user.present?
      redirect_to signup_path and return
    end
  end

  include Lev::HandleWith

  respond_to :html

  protected #################

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
