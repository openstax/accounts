class ApplicationController < ActionController::Base
  include ApplicationHelper
  include SignupHelper

  before_action :authenticate_user!
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

  include Lev::HandleWith

  respond_to :html

  protected

  def complete_signup_profile
    return true if request.format != :html || request.options?
    redirect_to profile_path if current_user.is_needs_profile?
  end

  def restart_signup_if_missing_unverified_user
    redirect_to signup_path and nil unless unverified_user.present?
  end
end
