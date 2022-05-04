class SessionsController < ApplicationController

  include RequireRecentSignin
  include RateLimiting

  skip_before_action :authenticate_user!,
                     only: [:start, :lookup_login, :authenticate, :redirect_back,
                            :create, :failure, :destroy]

  before_action :save_new_params_in_session, only:   [:start]

  before_action :store_authorization_url_as_fallback, only: :create

  before_action :maybe_skip_to_sign_up, only: [:start]

  # If the user arrives to :start already logged in, this means they got linked to
  # the login page somehow; attempt to redirect to the authorization url stored
  # earlier
  before_action :redirect_back, if: -> { signed_in? }, only: :start


  def lookup_login
    # Most rate limiting happens in CustomIdentity; this separate check needs to be here
    # here because bad username entries don't even make it all the way to CustomIdentity.

    if too_many_log_in_attempts_by_ip?(ip: request.ip)
      redirect_to root_url, alert: (I18n.t :"controllers.sessions.too_many_lookup_attempts")
    else
      handle_with(SessionsLookupLogin,
                  success: lambda do
                    set_login_state(username_or_email: @handler_result.outputs.username_or_email,
                                    matching_user_ids: @handler_result.outputs.user_ids,
                                    names:             @handler_result.outputs.names,
                                    providers:         @handler_result.outputs.providers.to_hash)
                    redirect_to :authenticate
                  end,
                  failure: lambda do
                    security_log :login_not_found, tried: @handler_result.outputs.username_or_email
                    set_login_state(username_or_email: @handler_result.outputs.username_or_email,
                                    matching_user_ids: @handler_result.outputs.user_ids)
                    redirect_to :login_path and return
                  end)
    end
  end

  def reauthenticate
    handle_with(SessionsReauthenticate,
                complete: lambda do
                  @username_or_email = @handler_result.outputs.username_or_email
                  @providers         = @handler_result.outputs.providers.to_hash
                end)
  end

  def authenticate
    redirect_to root_path if signed_in?
  end

  # Handle OAuth callback (actual login)
  # May add authentication method (OAuth provider) to account
  def create
    handle_with(
      SessionsCreate,
      user_state:      self,
      login_providers: get_login_state[:providers],
      success:         -> do
        authentication = @handler_result.outputs[:authentication]
        status         = @handler_result.outputs[:status]

        case status
          when :new_signin_required
            reauthenticate_user! # TODO maybe replace with static "session has expired" b/c hard to recover
          when :returning_user
            security_log :sign_in_successful, authentication_id: authentication.id
            redirect_to action: :redirect_back
          when :new_password_user
            security_log :sign_up_successful, authentication_id: authentication.id
            security_log :sign_in_successful, authentication_id: authentication.id
            redirect_to action: :redirect_back
          when :existing_user_signed_up_again
            # TODO security_log that user signed up again and we merged
            security_log :sign_in_successful, authentication_id: authentication.id
            redirect_to action: :redirect_back
          when :no_action
            security_log :sign_in_successful, authentication_id: authentication.id
            redirect_to action: :redirect_back
          when :new_social_user
            security_log :sign_in_successful, authentication_id: authentication.id
            redirect_to confirm_oauth_info_path
          when :authentication_added
            security_log :authentication_created,
                         authentication_id:       authentication.id,
                         authentication_provider: authentication.provider,
                         authentication_uid:      authentication.uid
            security_log :sign_in_successful, authentication_id: authentication.id
            redirect_to profile_path,
                        notice: I18n.t(:"controllers.sessions.new_sign_in_option_added")
          when :authentication_taken
            security_log :authentication_transfer_failed, authentication_id: authentication.id
            redirect_to profile_path,
                        alert: I18n.t(:"controllers.sessions.sign_in_option_already_used")
          when :same_provider
            security_log :authentication_transfer_failed, authentication_id: authentication.id
            redirect_to profile_path,
                        alert: I18n.t(:"controllers.sessions.same_provider_already_linked",
                                      user_name:      current_user.name,
                                      authentication: authentication.display_name)
          when :mismatched_authentication
            security_log :sign_in_failed, reason: "mismatched authentication"
            redirect_to login_path,
                        alert: I18n.t(:"controllers.sessions.mismatched_authentication")
          when :email_already_in_use
            redirect_to profile_path,
                        alert: I18n.t(:"controllers.sessions.way_to_login_cannot_be_added")
          else
            oauth               = request.env['omniauth.auth']
            errors              = @handler_result.errors.inspect
            last_exception      = $!.inspect
            exception_backtrace = $@.inspect

            error_message = "[SessionsCreate] IllegalState on success: " +
              "OAuth data: #{oauth}; status: #{status}; " +
              "errors: #{errors}; last exception: #{last_exception}; " +
              "exception backtrace: #{exception_backtrace}"

            # This will print the exception to the logs and send devs an exception email
            raise IllegalState, error_message
        end
      end,
      failure:         -> do
        errors    = @handler_result.errors
        lost_user = errors.any? do |error|
          [:unknown_callback_state, :invalid_omniauth_data].include? error.code
        end

        if lost_user
          # Something weird happened to the user's session or omniauth data and we lost their info
          Rails.logger.warn do
            oauth  = request.env['omniauth.auth']
            errors = @handler_result.errors.inspect

            "[SessionsCreate] Lost User on failure: " +
              "OAuth data: #{oauth}; status: #{status}; errors: #{errors}"
          end

          redirect_to root_path, alert: I18n.t(:'controllers.lost_user')
        else
          oauth               = request.env['omniauth.auth']
          errors              = @handler_result.errors.inspect
          last_exception      = $!.inspect
          exception_backtrace = $@.inspect

          error_message = "[SessionsCreate] IllegalState on failure: " +
            "OAuth data: #{oauth}; status: #{status}; " +
            "errors: #{errors}; last exception: #{last_exception}; " +
            "exception backtrace: #{exception_backtrace}"

          # This will print the exception to the logs and send devs an exception email
          raise IllegalState, error_message
        end
      end
    )
  end

  # Destroy session (logout)
  def destroy
    sign_out!

    # Now figure out where we should redirect the user...

    if return_url_specified_and_allowed?
      redirect_back
    else
      if params[:parent]
        url = iframe_after_logout_url(parent: params[:parent])
      end

      session[ActionInterceptor.config.default_key] = nil

      # Compute a default redirect based on the referrer's scheme, host, and port.
      # Add the request's query onto this URL (a way for the logging-out app to
      # communicate state back to itself).
      url ||= begin
                referrer_uri = URI(request.referer)
                request_uri  = URI(request.url)
                if referrer_uri.host == request_uri.host
                  "#{root_url}?#{request_uri.query}"
                else
                  "#{referrer_uri.scheme}://#{referrer_uri.host}:#{referrer_uri.port}/?#{request_uri.query}"
                end
              rescue # in case the referer is bad (see #179)
                root_url
              end

      redirect_to url
    end
  end

  def redirect_back
    super # defined in action_interceptor gem
  end

  # OAuth failure (e.g. wrong password)
  def failure
    if params[:message] == 'csrf_detected'
      redirect_to logout_path, alert: 'CSRF Error!'
      return
    end

    case params[:message]
      when 'cannot_find_user'
        flash[:alert] = I18n.t :"controllers.sessions.no_account_for_username_or_email"
        redirect_to :login_form_path and return
      when 'multiple_users'
        flash[:alert] = I18n.t :"controllers.sessions.several_accounts_for_one_email"
        redirect_to :login_form_path and return
      when 'bad_authenticate_password'
        field_error!(on: [:login, :password], code: :bad_password, message: :"controllers.sessions.incorrect_password")
        redirect_to :login_form_path and return
      when 'bad_reauthenticate_password'
        field_error!(on: [:login, :password], code: :bad_password, message: :"controllers.sessions.incorrect_password")
        reauthenticate # load state needed for render
        render :'login/reauthenticate_form'
      when 'too_many_login_attempts'
        flash[:alert] = I18n.t :"controllers.sessions.too_many_login_attempts.content",
                               reset_password: "<a href=\"#{password_send_reset_path}\">#{
                                 I18n.t :"controllers.sessions.too_many_login_attempts.reset_password"
                               }</a>".html_safe
        redirect_to :login_form_path and return
      when 'invalid_credentials'
        flash[:alert] = I18n.t :"controllers.sessions.trouble_with_provider"

        redirect_to :login_form_path and return
      else
        flash[:alert] = params[:message]
        render :'signup/welcome'
    end
  end

  private

  def save_new_params_in_session
    set_client_app(params[:client_id])
    set_alternate_signup_url(params[:signup_at])
    set_student_signup_role(params[:go] == 'student_signup')
  end

  def maybe_skip_to_sign_up
    if %w{signup student_signup}.include?(params[:go])
      redirect_to signup_path(role: 'student')
    end
  end

  def store_authorization_url_as_fallback
    # In case we need to redirect_back, but don't have something to redirect back
    # to (e.g. no authorization url or referrer), form and store as the fallback
    # an authorization URL.  Handles the case where the user got sent straight to
    # the login page.  Only works if we have know the client app.

    client_app = get_client_app
    return if client_app.nil?

    redirect_uri      = client_app.redirect_uri.lines.first.chomp
    authorization_url = oauth_authorization_url(client_id:     client_app.uid,
                                                redirect_uri:  redirect_uri,
                                                response_type: 'code')

    store_fallback(url: authorization_url) unless authorization_url.nil?
  end

  def field_error!(on:, code:, message:)
    @errors ||= Lev::Errors.new
    message = I18n.t(message) if message.is_a?(Symbol)
    @errors.add(false, offending_inputs: on, code: code, message: message)
  end
end

