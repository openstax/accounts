module SignInState

  # References:
  #   http://railscasts.com/episodes/356-dangers-of-session-hijacking

  # Always return an object
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    @current_user ||= AnonymousUser.instance
  end

  def sign_in!(user)
    clear_login_info # TODO rename ...login_state AND rename sign_in_state to log_in_state
    @current_user = user || AnonymousUser.instance

    if @current_user.is_anonymous?
      session[:user_id] = nil
    else
      session[:user_id] = @current_user.id
      session[:last_admin_activity] = DateTime.now.to_s \
        if @current_user.is_administrator? && is_real_production_site?
    end

    @current_user
  end

  def sign_out!
    session.delete(:signup) # TODO call as clear_signup_state or something
    sign_in!(AnonymousUser.instance)
  end

  def signed_in?
    !current_user.is_anonymous?
  end

  def authenticate_user!
    return if signed_in?

    store_url
    redirect_to main_app.login_path(params.slice(:client_id))
  end

  def authenticate_admin!
    return if current_user.is_administrator?

    store_url
    redirect_to main_app.login_path(params.slice(:client_id))
  end

  def is_real_production_site?
    request.host == 'accounts.openstax.org'
  end

  # Doorkeeper controllers define authenticate_admin!, so we need another name
  alias_method :admin_authentication!, :authenticate_admin!

end
