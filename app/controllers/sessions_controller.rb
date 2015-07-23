# References:
#   https://gist.github.com/stefanobernardi/3769177

class SessionsController < ApplicationController

  skip_before_filter :authenticate_user!, :expired_password, :registration,
                     only: [:new, :callback, :failure, :destroy]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:new, :callback, :failure,
                         :destroy, :ask_new_or_returning]

  def new
    store_fallback
    referer = request.referer
    session[:from_cnx] = (referer =~ /cnx\.org/) unless referer.blank?
    session[:client_id] = params[:client_id]
    @application = Doorkeeper::Application.where(uid: params[:client_id]).first
  end

  def callback
    handle_with(SessionsCallback, user_state: self,
      complete: lambda {
        case @handler_result.outputs[:status]
        when :returning_user    then redirect_to action: :returning_user
        when :new_user          then render :ask_new_or_returning
        when :multiple_accounts then render :ask_which_account
        else                    raise IllegalState
        end
      })
  end

  def destroy
    session[ActionInterceptor.config.default_key] = nil
    session[:registration_return_to] = nil
    session[:client_id] = nil

    sign_out!

    # Hack to find root of referer
    # This will be a problem if we have to redirect back to apps
    # that are not at the root of their host after logout
    # TODO: Replace with signed or registered return urls
    #       Need to provide web views to sign or register those urls
    url = begin
      uri = URI(request.referer)
      "#{uri.scheme}://#{uri.host}:#{uri.port}/"
    rescue # in case the referer is bad (see #179)
      root_url
    end

    redirect_to url, notice: "Signed out!"
  end

  def ask_new_or_returning
  end

  def i_am_returning
  end

  # This is an official action instead of just doing `redirect_back` in callback
  # handler so that fine_print can check to see if terms need to be signed.
  def returning_user
    redirect_back
  end

  # Omniauth failure endpoint
  def failure
    flash.now[:alert] = params[:message] == 'invalid_credentials' ? \
                          'Incorrect username or password' : \
                          params[:message]
    render 'new'
  end

end
