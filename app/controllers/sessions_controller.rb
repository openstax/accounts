# References:
#   https://gist.github.com/stefanobernardi/3769177
require 'ostruct'

class SessionsController < ApplicationController

  include RequireRecentSignin

  skip_before_filter :authenticate_user!, :check_if_password_expired,
                     only: [:new, :lookup_login, :authenticate,
                            :create, :failure, :destroy, :email_usernames]

  skip_before_filter :complete_signup_profile, only: [:destroy]

  before_filter :get_authorization_url, only: [:new, :create]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:new, :lookup_login, :authenticate, :create, :failure, :destroy, :redirect_back, :email_usernames]

  # Login form
  def new
    # If no url to redirect back to, store the fallback url
    # (the authorization url or the referer)
    # Handles the case where the user got sent straight to the login page
    options = @authorization_url.nil? ? {} : { url: @authorization_url }
    store_fallback(options)

    # If the user is already logged in, this means they got linked to the login page somehow
    # Attempt to redirect to the fallback url stored above
    redirect_back if signed_in? && !params[:required]

    session[:client_id] = params[:client_id]
    @application = Doorkeeper::Application.where(uid: params[:client_id]).first
  end

  def lookup_login
    handle_with(SessionsLookupLogin,
                success: lambda do
                  set_login_state(username_or_email: @handler_result.outputs.username_or_email,
                                  matching_user_ids: @handler_result.outputs.user_ids,
                                  names: @handler_result.outputs.names,
                                  providers: @handler_result.outputs.providers.to_hash)
                  redirect_to :authenticate
                end,
                failure: lambda do
                  set_login_state(username_or_email: @handler_result.outputs.username_or_email,
                                  matching_user_ids: @handler_result.outputs.user_ids)
                  render :new
                end)
  end

  def reauthenticate
    handle_with(SessionsReauthenticate,
                complete: lambda do
                  @username_or_email = @handler_result.outputs.username_or_email
                  @providers = @handler_result.outputs.providers.to_hash
                end)
  end

  def authenticate
    redirect_to root_path if signed_in?
  end

  # Handle OAuth callback (actual login)
  # May add authentication method (OAuth provider) to account
  def create
    # If we have a client_id but no url to redirect back to,
    # store the fallback url (the authorization page)
    # However, do not store the referrer if the client_id is not present
    # The referrer in this case is most likely the login page
    # and we don't want to send users back there
    store_fallback(url: @authorization_url) unless @authorization_url.nil?

    handle_with(
      SessionsCreate,
      user_state: self,
      signup_state: signup_state,
      login_providers: get_login_state[:providers],
      complete: lambda do
        authentication = @handler_result.outputs[:authentication]
        case @handler_result.outputs[:status]
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
          redirect_to signup_profile_path
        when :authentication_added
          security_log :authentication_created,
                       authentication_id: authentication.id,
                       authentication_provider: authentication.provider,
                       authentication_uid: authentication.uid
          security_log :sign_in_successful, authentication_id: authentication.id
          redirect_to profile_path, notice: (I18n.t :"controllers.sessions.new_sign_in_option_added")
        when :authentication_taken
          security_log :authentication_transfer_failed, authentication_id: authentication.id
          redirect_to profile_path, alert: (I18n.t :"controllers.sessions.sign_in_option_already_used")
        when :same_provider
          security_log :authentication_transfer_failed, authentication_id: authentication.id
          redirect_to profile_path, alert: (I18n.t :"controllers.sessions.same_provider_already_linked",
                                                   user_name: current_user.name,
                                                   authentication: authentication.display_name)
        when :mismatched_authentication
          # TODO new security log entry
          redirect_to action: :authenticate, alert: "Mismatched login!" # TODO need feature spec!
        else
          Rails.logger.fatal "IllegalState: OAuth data: #{request.env['omniauth.auth']}; " \
                             "status: #{@handler_result.outputs[:status]}"
          raise IllegalState, "SessionsCreate errors: #{@handler_result.errors.inspect
                              }; Last exception: #{$!.inspect}; Exception backtrace: #{$@.inspect
                              }; status: #{@handler_result.outputs[:status]}"
        end
      end
    )
  end

  # Destroy session (logout)
  def destroy
    if params[:parent]
      url = iframe_after_logout_url(parent: params[:parent])
    end
    session[ActionInterceptor.config.default_key] = nil
    session[:client_id] = nil

    sign_out!

    # Hack to find root of referer; also send back any query parameters on the logout
    # request (a way for the logging out application to communicate state back to itself)
    # This will be a problem if we have to redirect back to apps
    # that are not at the root of their host after logout
    # TODO: Replace with signed or registered return urls
    #       Need to provide web views to sign or register those urls
    url ||= begin
      referrer_uri = URI(request.referer)
      request_uri = URI(request.url)
      "#{referrer_uri.scheme}://#{referrer_uri.host}:#{referrer_uri.port}/?#{request_uri.query}"
    rescue # in case the referer is bad (see #179)
      root_url
    end

    redirect_to url
  end

  # This is an official action so that fine_print can check to see if terms need to be signed
  def redirect_back
    super
  end

  # OAuth failure (e.g. wrong password)
  def failure
    if params[:message] == 'csrf_detected'
      redirect_to logout_path, alert: 'CSRF Error!'
      return
    end

    case params[:message]
    when 'cannot_find_user'
      flash[:alert] = I18n.t :"errors.no_account_for_username_or_email"
      render :new
    when 'multiple_users'
      flash[:alert] = I18n.t :"controllers.sessions.several_accounts_for_one_email"
      render :new
    when 'bad_password'
      field_error!(on: [:login, :password], code: :bad_password, message: :"controllers.sessions.incorrect_password")
      render :authenticate
    when 'too_many_login_attempts'
      flash[:alert] = I18n.t :"controllers.sessions.too_many_login_attempts.content",
                             reset_password: "<a href=\"#{password_send_reset_path}\">#{
                               I18n.t :"controllers.sessions.too_many_login_attempts.reset_password"
                             }</a>".html_safe
      render :authenticate
    else
      flash[:alert] = params[:message]
      render :new
    end
  end

  def email_usernames
    usernames = User.where{id.in my{get_login_state[:matching_user_ids]}}.map(&:username)

    SignInHelpMailer.multiple_accounts(
      email_address: get_login_state[:username_or_email],
      usernames: usernames
    ).deliver_later

    respond_to do |format|
      format.js
    end
  end

  protected

  def get_authorization_url
    client_id = params[:client_id] || session[:client_id]
    client_app = Doorkeeper::Application.where(uid: client_id).first
    return if client_app.nil?

    redirect_uri = client_app.redirect_uri.lines.first.chomp
    @authorization_url = oauth_authorization_url(client_id: client_id,
                                                 redirect_uri: redirect_uri,
                                                 response_type: 'code')
  end

end
