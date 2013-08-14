# References:
#   https://gist.github.com/stefanobernardi/3769177

class SessionsController < ApplicationController

  def new
    logger.debug('in new')
  end

  def create
    auth = request.env['omniauth.auth']
    logger.debug(auth.to_yaml)
    # TODO if new user, before set current_user, ask if have logged in before so can reuse existing user
    self.current_user = ProcessOmniauthAuthentication.exec(auth, current_user)
    redirect_to session.delete(:return_to) || root_url
  end

  def destroy
    self.current_user = nil
    redirect_to root_path, notice: "Signed out!"
  end

  def failure
    render "new", alert: "Authentication failed, please try again."
  end

end
