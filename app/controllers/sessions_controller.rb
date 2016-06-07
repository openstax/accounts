# References:
#   https://gist.github.com/stefanobernardi/3769177

class SessionsController < ApplicationController

  skip_before_filter :authenticate_user!, :expired_password,
                     only: [:new, :callback, :failure, :destroy, :help]

  skip_before_filter :finish_sign_up, only: [:destroy]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:new, :callback, :failure, :destroy, :help]

  helper_method :last_signin_provider

  def new
    get_authorization_url
    options = @authorization_url.nil? ? {} : { url: @authorization_url }
    # If no url to redirect back to, store the fallback url (the authorization url or the referer)
    # Handles the case where the user got sent straight to the login page
    store_fallback(options)

    # If the user is already logged in, this means they got linked to the login page somehow
    # Attempt to redirect to the fallback url stored above
    redirect_back if signed_in?

    session[:client_id] = params[:client_id]
    @application = Doorkeeper::Application.where(uid: params[:client_id]).first
  end

  def callback
    get_authorization_url
    # If we have a client_id but no url to redirect back to,
    # store the fallback url (the authorization page)
    # However, do not store the referrer if the client_id is not present
    # The referrer in this case is most likely the login page
    # and we don't want to send users back there
    store_fallback(url: @authorization_url) unless @authorization_url.nil?

    handle_with(
      SessionsCallback,
      user_state: self,
      complete: lambda do
        authentication = @handler_result.outputs[:authentication]

        case @handler_result.outputs[:status]
        when :returning_user
          set_last_signin_provider(authentication.provider)
          security_log :sign_in_successful, authentication_id: authentication.id
          redirect_to action: :returning_user
        when :new_password_user
          set_last_signin_provider(authentication.provider)
          security_log :sign_up_successful, authentication_id: authentication.id
          redirect_to action: :returning_user
        when :transferred_authentication
          set_last_signin_provider(authentication.provider)
          security_log :authentication_transferred, authentication_id: authentication.id
          redirect_to action: :returning_user
        when :no_action
          redirect_to action: :returning_user
        when :new_social_user
          security_log :sign_in_successful, authentication_id: authentication.id
          redirect_to signup_social_path
        when :authentication_added
          security_log :authentication_created, authentication_id: authentication.id,
                                                authentication_provider: authentication.provider,
                                                authentication_uid: authentication.uid
          redirect_to profile_path, notice: "Your new sign in option has been added!"
        when :authentication_taken
          redirect_to profile_path, alert: "That sign in option is already used by someone " \
                                           "else.  If that someone is you, remove it from " \
                                           "your other account and try again."
        else
          raise IllegalState, "SessionsCallback errors: #{@handler_result.errors.map(&:code).join(', ')}; Last exception: #{$!.inspect}; Exception backtrace: #{$@.inspect}"
        end
      end
    )
  end

  # This is an official action instead of just doing `redirect_back` in callback
  # handler so that fine_print can check to see if terms need to be signed.
  def returning_user
    redirect_back
  end

  def destroy
    security_log :sign_out
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

  def help
    if request.post?
      handle_with(SessionsHelp,
                  success: lambda do
                    security_log :help_requested
                    redirect_to root_path,
                                notice: 'Instructions for accessing your OpenStax account have been emailed to you.'
                  end,
                  failure: lambda do
                    security_log :help_request_failed, username_or_email: params[:username_or_email]
                    render :help, status: 400
                  end)
    end
  end

  # Omniauth failure endpoint
  def failure
    security_log :sign_in_failed, reason: params[:message]
    flash.now[:alert] =
      case params[:message]
      when 'cannot_find_user'
        "We have no account for the username or email you provided.  " \
        "Email addresses must be verified in our system to use them during sign in."
      when 'multiple_users'
        "We found several accounts with your email address.  Please sign in using your username."
      when 'bad_password'
        "The password you provided is incorrect."
      else
        params[:message]
      end
    render 'new'
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
