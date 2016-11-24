module UserSessionManagement

  # References:
  #   http://railscasts.com/episodes/356-dangers-of-session-hijacking

  # Always return an object
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    @current_user ||= AnonymousUser.instance
  end

  def sign_in!(user)
    clear_login_state
    @current_user = user || AnonymousUser.instance

    if @current_user.is_anonymous?
      session[:user_id] = nil
    else
      session[:user_id] = @current_user.id
      session[:last_admin_activity] = DateTime.now.to_s \
        if @current_user.is_administrator?
    end

    @current_user
  end

  def sign_out!
    clear_signup_state
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

  # Doorkeeper controllers define authenticate_admin!, so we need another name
  alias_method :admin_authentication!, :authenticate_admin!

  def set_login_state(username_or_email: nil, matching_user_ids: nil, names: nil, providers: nil)
    session[:login] = {
      'u' => username_or_email,
      'm' => matching_user_ids,
      'n' => names,
      'p' => providers
    }
  end

  def get_login_state
    {
      username_or_email: session[:login].try(:[],'u'),
      matching_user_ids: session[:login].try(:[], 'm'),
      names: session[:login].try(:[],'n'),
      providers: session[:login].try(:[],'p')
    }
  end

  def clear_login_state
    session.delete(:login)
  end

  def save_signup_state(role:, signup_contact_info_id:)
    session[:signup] = {
      'r' => role,
      'c' => signup_contact_info_id
    }
  end

  def clear_signup_state
    session.delete(:signup)
  end

  def signup_role
    session[:signup].try(:[], 'r')
  end

  def signup_contact_info
    @signup_contact_info ||= SignupContactInfo.find_by(id: session[:signup].try(:[],'c'))
  end

  def signup_email
    @signup_email ||= signup_contact_info.try(:value)
  end

end
