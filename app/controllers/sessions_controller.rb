# References:
#   https://gist.github.com/stefanobernardi/3769177

class SessionsController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:new, :callback,
                                                 :failure, :destroy]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:new, :callback, :failure,
                                    :destroy, :ask_new_or_returning]

  prepend_before_filter :check_registered, only: [:return_to_app]
  prepend_before_filter :check_password_not_expired, only: [:return_to_app]

  # Put some of this in an authentications controller?

  def new
    referer = request.referer
    session[:from_cnx] = (referer =~ /cnx\.org/) unless referer.blank?
    session[:application_id] = params[:client_id]
    @application = Doorkeeper::Application.where(uid: params[:client_id]).first
  end

  def callback
    handle_with(SessionsAuthenticated,
                user_state: self,
                complete: lambda {
                  case @handler_result.outputs[:next_action]
                  when :return_to_app         then redirect_to return_to_app_path   
                  when :ask_new_or_returning  then render :ask_new_or_returning              
                  when :ask_which_account     then render :ask_which_account   
                  else                             raise IllegalState
                  end    
                })
  end

  def return_to_app
    redirect_to session.delete(:return_to) || root_url
  end

  def destroy
    sign_out!
    redirect_to params[:return_to] || root_path, notice: "Signed out!"
  end

  def failure
    flash[:alert] = "Incorrect username or password, please try again."
    render "new"
  end

  protected

  def check_registered
    redirect_to register_path if current_user.is_temp
  end

  def check_password_not_expired
    if current_user.try(:identity).try(:should_reset_password?)
      identity = current_user.identity
      identity.generate_reset_code
      redirect_to reset_password_path(code: identity.reset_code)
    end
  end

end
