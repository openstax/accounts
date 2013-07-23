# References:
#   http://railscasts.com/episodes/356-dangers-of-session-hijacking

class ApplicationController < ActionController::Base
  protect_from_forgery

protected

  helper_method :current_user, :signed_in?

  def current_user
    if !request.ssl? || cookies.signed[:secure_user_id] == "secure#{session[:user_id]}"
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end
  end
 
  def signed_in?
    !!current_user
  end
 
  def current_user=(user)
    @current_user = user

    if user.nil?
      session[:user_id] = nil
      cookies.delete[:secure_user_id]
    else
      session[:user_id] = user.id
      cookies.signed[:secure_user_id] = {secure: true, value: "secure#{user.id}"}
    end
  end

end
