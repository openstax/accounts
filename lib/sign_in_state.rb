module SignInState

  # References:
  #   http://railscasts.com/episodes/356-dangers-of-session-hijacking

  # Always return an object
  def current_user
    if !request.ssl? || cookies.signed[:secure_user_id] == "secure#{session[:user_id]}"
      @current_user ||= AnonymousUser.instance

      if @current_user.is_anonymous? && session[:user_id]
        # Use current_user= to clear out bad state if any
        self.current_user = User.where(id: session[:user_id]).first
      end

      @current_user
    end
  end
 
  def current_user=(user)
    @current_user = user || AnonymousUser.instance
    if @current_user.is_anonymous?
      session[:user_id] = nil
      cookies.delete(:secure_user_id)
    else
      session[:user_id] = @current_user.id
      cookies.signed[:secure_user_id] = {secure: true, value: "secure#{@current_user.id}"}
    end
    @current_user
  end

  def sign_in(user)
    self.current_user = user
  end

  def sign_out!
    self.current_user = AnonymousUser.instance
  end

  def signed_in?
    !current_user.is_anonymous?
  end


end