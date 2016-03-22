# References:
#   https://gist.github.com/stefanobernardi/3769177

class SessionsController < ApplicationController

  skip_before_filter :authenticate_user!, :expired_password,
                     only: [:new, :callback, :failure, :destroy, :help]

  skip_before_filter :finish_sign_up, only: [:destroy]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:new, :callback, :failure, :destroy, :help]

  def new
    get_authorization_url
    options = @authorization_url.nil? ? {} : { url: @authorization_url }
    # If no url to redirect back to, store the fallback url (the authorization url or the referer)
    # Handles the case where the user got sent straight to the login page
    store_fallback(options)

    # If the user is already logged in, this means they got linked to the login page somehow
    # Attempt to redirect to the fallback url stored above
    redirect_back if signed_in?

    # Hack to figure out if the user came from CNX to hide the login
    # In the future, use the client_id and some boolean flag in the client app
    referer = request.referer

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

    handle_with(SessionsCallback, user_state: self,
      complete: lambda {
        case @handler_result.outputs[:status]
        when :returning_user, :new_password_user, :transferred_authentication
          redirect_to action: :returning_user
        when :new_social_user
          redirect_to signup_social_path
        when :authentication_added
          redirect_to profile_path
        else
          raise IllegalState
        end
      })
  end

  # This is an official action instead of just doing `redirect_back` in callback
  # handler so that fine_print can check to see if terms need to be signed.
  def returning_user
    redirect_back
  end

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

  def help
    if request.post?
      handle_with(SessionsHelp,
                  success: lambda { # TODO change the notice to be less about "passwords"
                    redirect_to root_path, notice: 'Password reset instructions sent to your email address!'
                  },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :help, status: errors ? 400 : 200
                  })
    end
  end

  # Omniauth failure endpoint
  def failure
    flash.now[:alert] = params[:message] == 'invalid_credentials' ? \
                          'Incorrect username, email, or password' : \
                          params[:message]
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
