# References:
#   https://gist.github.com/stefanobernardi/3769177

class SessionsController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:new, :authenticated, :failure]

  # Put some of this in an authentications controller?

  def new
    @application = Doorkeeper::Application.where(uid: params[:client_id]).first
  end

  def authenticated
    handle_with(SessionsAuthenticated,
                user_state: self,
                complete: lambda {
                  case @handler_result.outputs[:next_action]
                  when :return_to_app         then return_to_app
                  when :ask_new_or_returning  then render :ask_new_or_returning
                  when :ask_which_account     then render :ask_which_account
                  else                             raise IllegalState
                  end    
                })
  end

  def ask_new_or_returning; end

  def ask_which_account; end

  def finish_registration
    # if user profile info good to go, change in user and return_to_app!
    # otherwise render register with error messages

    handle_with(SessionsFinishRegistration, 
                success: lambda { return_to_app },
                failure: lambda { render :register })
  end

  def register
    # raise SecurityTransgression unless current_user.is_temp
  end

  def destroy
    sign_out!
    redirect_to root_path, notice: "Signed out!"
  end

  def failure
    flash[:alert] = "Incorrect username or password, please try again."
    render "new"
  end

protected

  def return_to_app
    FinishUserCreation.call(current_user)
    redirect_to session.delete(:return_to) || root_url
  end

end
