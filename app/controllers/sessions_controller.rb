# References:
#   https://gist.github.com/stefanobernardi/3769177

class SessionsController < ApplicationController

  def new
    logger.debug('in new')
  end

  def authenticated
    auth = request.env['omniauth.auth']
    logger.debug(auth.to_yaml)
    # TODO if new user, before set current_user, ask if have logged in before so can reuse existing user
    # self.current_user = ProcessOmniauthAuthentication.exec(auth, current_user)

    next_action = HandleOmniauthAuthentication.call(auth, self)

    case next_action
    when :return_to_app
      return_to_app
    when :ask_new_or_returning
      render :ask_new_or_returning
    when :ask_which_account
      render :ask_which_account
    else
      raise IllegalState
    end    
  end

  def ask_new_or_returning

  end

  def ask_which_account

  end

  def i_am_new
    return_to_app
  end

  def i_am_returning
    render :new
  end

  def destroy
    self.current_user = nil
    redirect_to root_path, notice: "Signed out!"
  end

  def failure
    render "new", alert: "Authentication failed, please try again."
  end

protected

  def return_to_app
    logger.debug("in return to app #{session[:return_to]}")
    FinishUserCreation.call(current_user)
    redirect_to session.delete(:return_to) || root_url
  end

end
