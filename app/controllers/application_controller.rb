class ApplicationController < ActionController::Base

  layout 'application'

  prepend_before_action :validate_signed_params_if_present

  before_action :authenticate_user!
  before_action :complete_signup_profile
  before_action :check_if_password_expired

  fine_print_require :general_terms_of_use, :privacy_policy, unless: :disable_fine_print

  def newflow_feature_flag
    if request.get? && Settings::Db.store.newflow_feature_flag && !params[:bpff].present? # bpff = bypass feature flag
      redirect_to newflow_login_path(request.query_parameters)
    end
  end

  def disable_fine_print
    request.options? ||
    contracts_not_required ||
    current_user.is_anonymous?
  end

  def complete_signup_profile
    return true if request.format != :html || request.options?
    redirect_to '/signup/profile' if current_user.is_needs_profile?
    # TODO: uncomment this line after fixing openstax_path_prefixer
    # redirect_to main_app.signup_profile_path if current_user.is_needs_profile?
  end

  def check_if_password_expired
    return true if request.format != :html || request.options?

    identity = current_user.identity
    return unless identity.try(:password_expired?)

    flash[:alert] = I18n.t :"controllers.identities.password_expired"
    redirect_to password_reset_path
  end

  def return_url_specified_and_allowed?
    # This returns true if `save_redirect` actually saved the URL
    params[:r] && params[:r] == stored_url
  end

  def validate_signed_params_if_present
    return true if signed_params.empty?

    app = ::Doorkeeper::Application.find_by_uid(params[:client_id])

    if app.nil?
      Rails.logger.warn { "Unknown app for signed parameters" }
      head(:bad_request)
    elsif !OpenStax::Api::Params.signature_and_timestamp_valid?(params: signed_params, secret: app.secret)
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

  def save_new_params_in_session
    # Store these params in the session so they are available if the lookup_login
    # fails.  Also these methods perform checks on the alternate signup URL.
    set_client_app(params[:client_id])
    set_alternate_signup_url(params[:signup_at])

    # TODO: if feature flag is ON, this is actually doing a redirect, not saving params in session.
    set_student_signup_role(params[:go] == 'student_signup')
  end

  def maybe_skip_to_sign_up
    if %w{signup student_signup}.include?(params[:go])
      if Settings::Db.store.newflow_feature_flag
        redirect_to newflow_signup_student_path
      else
        redirect_to signup_path
      end
    end
  end

  def store_authorization_url_as_fallback
    # In case we need to redirect_back, but don't have something to redirect back
    # to (e.g. no authorization url or referrer), form and store as the fallback
    # an authorization URL.  Handles the case where the user got sent straight to
    # the login page.  Only works if we have know the client app.

    client_app = get_client_app
    return if client_app.nil?

    redirect_uri = client_app.redirect_uri.lines.first.chomp
    authorization_url = oauth_authorization_url(client_id: client_app.uid,
                                                redirect_uri: redirect_uri,
                                                response_type: 'code')

    store_fallback(url: authorization_url) unless authorization_url.nil?
  end
end
