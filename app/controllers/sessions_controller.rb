# References:
#   https://gist.github.com/stefanobernardi/3769177

class SessionsController < ApplicationController

  acts_as_interceptor

  skip_before_filter :authenticate_user!,
                     only: [:new, :callback, :failure, :destroy]
  skip_interceptor :expired_password, :registration,
                    only: [:new, :callback, :failure, :destroy]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:new, :callback, :failure,
                                    :destroy, :ask_new_or_returning]

  def new
    referer = request.referer
    session[:from_cnx] = (referer =~ /cnx\.org/) unless referer.blank?
    @application = Doorkeeper::Application.where(uid: params[:client_id]).first
  end

  def callback
    handle_with(SessionsCallback, user_state: self,
      complete: lambda {
        case @handler_result.outputs[:status]
        when :returning_user    then redirect_back
        when :new_user          then render :ask_new_or_returning
        when :multiple_accounts then render :ask_which_account
        else                    raise IllegalState
        end
      })
  end

  def destroy
    sign_out!

    # Hack to find root of referer
    # This will be a problem if we have to redirect back to apps
    # that are not at the root of their host after logout
    # TODO: Replace with signed or registered return urls
    #       Need to provide web views to sign or register those urls
    uri = URI(request.referer)
    url = "#{uri.scheme}://#{uri.host}:#{uri.port}/"

    without_interceptor { redirect_to url, notice: "Signed out!" }
  end

  def ask_new_or_returning
  end

  def i_am_returning
  end

  # Omniauth failure endpoint
  def failure
    flash.now[:alert] = params[:message] == 'invalid_credentials' ? \
                          'Incorrect username or password' : \
                          params[:message]
    render 'new'
  end

end
