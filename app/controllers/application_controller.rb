class ApplicationController < ActionController::Base

  protect_from_forgery

  layout 'application'

  prepend_before_action :verify_signed_params

  before_action :authenticate_user!
  before_action :complete_signup_profile
  before_action :check_if_password_expired
  before_action :set_locale

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :disable_fine_print

  def disable_fine_print
    request.options? ||
    contracts_not_required ||
    current_user.is_anonymous?
  end

  def complete_signup_profile
    return true if request.format != :html || request.options?
    redirect_to main_app.signup_profile_path if current_user.is_needs_profile?
  end

  def check_if_password_expired
    return true if request.format != :html || request.options?

    identity = current_user.identity
    return unless identity.try(:password_expired?)

    flash[:alert] = I18n.t :"controllers.identities.password_expired"
    redirect_to password_reset_path
  end

  def return_url_specified_and_allowed?
    # This returns true iff `save_redirect` actually saved the URL
    params[:r] && params[:r] == stored_url
  end

  def verify_signed_params
    return true if params[:sp].nil?

    app = ::Doorkeeper::Application.find_by_uid(params[:client_id])

    if app.nil?
      Rails.logger.warn { "Unknown app for signed parameters" }
      head(:bad_request)
    elsif !OpenStax::Api::Params.signature_and_timestamp_valid?(params: params[:sp], secret: app.secret)
      Rails.logger.warn { "Invalid signature or timestamp for signed parameters" }
      head(:bad_request)
    end
  end

  include Lev::HandleWith

  respond_to :html

  protected

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

  def field_error!(on:, code:, message:)
    @errors ||= Lev::Errors.new
    message = I18n.t(message) if message.is_a?(Symbol)
    @errors.add(false, offending_inputs: on, code: code, message: message)
  end

end
