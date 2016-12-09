class ApplicationController < ActionController::Base

  include Lev::HandleWith

  before_filter :complete_signup_profile
  before_filter :check_if_password_expired

  respond_to :html

  protected

  def allow_iframe_access
    @iframe_parent = params[:parent]

    if @iframe_parent.blank?
      response.headers.except! 'X-Frame-Options'
      return true
    end

    valid_origins = Rails.application.secrets[:valid_iframe_origins] || []
    if valid_origins.any?{|origin| @iframe_parent =~ /^#{origin}/ }
      response.headers.except! 'X-Frame-Options'
    else
      raise SecurityTransgression.new("#{@iframe_parent} is not allowed to iframe content")
    end
    true
  end

  def field_error!(on:, code:, message:)
    @errors ||= Lev::Errors.new
    message = I18n.t(message) if message.is_a?(Symbol)
    @errors.add(false, offending_inputs: on, code: code, message: message)
  end

  def is_redirect_url?(application:, url:)
    return false if application.nil? || url.nil?
    # Let doorkeeper do the work of checking the URL against the app's redirect_uris
    Doorkeeper::OAuth::Helpers::URIChecker.valid_for_authorization?(url, application.redirect_uri)
  end

  def complete_signup_profile
    return true if request.format != :html
    redirect_to signup_profile_path if current_user.is_needs_profile?
  end

  def check_if_password_expired
    return true if request.format != :html

    identity = current_user.identity
    return unless identity.try(:password_expired?)

    flash[:alert] = I18n.t :"controllers.identities.password_expired"
    redirect_to password_reset_path
  end

end
