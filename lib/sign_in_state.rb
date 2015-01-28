module SignInState

  # References:
  #   http://railscasts.com/episodes/356-dangers-of-session-hijacking

  # Always return an object
  def current_user
    if request.ssl? && \
       cookies.signed[:secure_user_id] != "secure#{session[:user_id]}"
      sign_out! # hijacked
    else
      @current_user ||= User.where(id: session[:user_id]).first \
        if session[:user_id]
      @current_user ||= AnonymousUser.instance
    end

    @current_user
  end
 
  def sign_in!(user)
    @current_user = user || AnonymousUser.instance
    if @current_user.is_anonymous?
      session[:user_id] = nil
      cookies.delete(:secure_user_id)
    else
      session[:user_id] = @current_user.id
      cookies.signed[:secure_user_id] = { secure: true,
                                          value: "secure#{@current_user.id}" }
    end

    @current_user
  end

  def sign_out!
    sign_in!(AnonymousUser.instance)
  end

  def signed_in?
    !current_user.is_anonymous?
  end

  def authenticate_user!
    with_interceptor do
      redirect_to main_app.login_path(params.slice(:client_id)),
                  notice: "Please log in." unless signed_in?
    end
  end

  def authenticate_admin!
    with_interceptor do
      redirect_to main_app.login_path(params.slice(:client_id)),
                  notice: "Please log in." unless current_user.is_administrator?
    end
  end

  # Doorkeeper controllers define authenticate_admin!, so we need another name
  alias_method :admin_authentication!, :authenticate_admin!

end
