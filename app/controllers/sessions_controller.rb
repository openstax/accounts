# References:
#   https://gist.github.com/stefanobernardi/3769177

class SessionsController < ApplicationController

  # Put some of this in an authentications controller?

  def new; end

  def authenticated
    handle_with(SessionsAuthenticated,
                user_state: self,
                complete: lambda {
                  case @results[:next_action]
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

    handle_with(Handlers::UpdateUser, 
                params: params['user'],
                success: lambda { return_to_app },
                failure: lambda { render :register })
  end

  def register
  end

  def destroy
    sign_out!
    redirect_to root_path, notice: "Signed out!"
  end

  def failure
    render "new", alert: "Authentication failed, please try again."
  end

protected

  # def return_to_app
  #   current_user.is_temp? ?   # really should not return :return_to_app, but :register_user instead
  #     redirect_to(sessions_register_path) :
  #     return_to_app!
  # end

  def return_to_app
    FinishUserCreation.call(current_user)
    redirect_to session.delete(:return_to) || root_url
  end

end
