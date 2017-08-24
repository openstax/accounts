require 'oauth'

module UserSessionManagement

  # References:
  #   http://railscasts.com/episodes/356-dangers-of-session-hijacking

  # Always return an object
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    @current_user ||= AnonymousUser.instance
  end

  def sign_in!(user, options={})
    options[:security_log_data] ||= {}

    session[:client_id] = nil
    session[:alt_signup] = nil

    clear_login_state
    @current_user = user || AnonymousUser.instance

    if @current_user.is_anonymous?
      session[:user_id] = nil
      security_log :sign_out
    else
      session[:user_id] = @current_user.id
      session[:last_admin_activity] = DateTime.now.to_s \
        if @current_user.is_administrator?
      security_log :sign_in_successful, options[:security_log_data]
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
    redirect_to(
      main_app.login_path(
        params.slice(
          :client_id, :signup_at, :go, :no_signup, :email, :name, :role,
          :lti_signature, :timestamp,
        )
      )
    )
  end

  def authenticate_admin!
    return if current_user.is_administrator?

    store_url
    redirect_to main_app.login_path(params.slice(:client_id))
  end

  # Doorkeeper controllers define authenticate_admin!, so we need another name
  alias_method :admin_authentication!, :authenticate_admin!

  def set_login_state(username_or_email: nil, matching_user_ids: nil, names: nil, providers: nil)
    clear_signup_state
    session[:login] = {
      'u' => username_or_email,
      'm' => matching_user_ids,
      'n' => names,
      'p' => providers
    }
  end

  def get_login_state
    clear_login_state if signed_in? # should have happened already, but may not have

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

  def save_signup_state(signup_state)
    clear_login_state
    # There may be an old signup state object around, check for that
    clear_signup_state if signup_state.id != session[:signup]
    session[:signup] = signup_state.id
  end

  def clear_signup_state
    signup_state.try(:destroy)
    @signup_state = nil
    session.delete(:signup)
  end

  def signup_state
    id = session[:signup].to_i rescue nil
    @signup_state ||= SignupState.find_by(id: id)
  end

  def signup_role
    signup_state.try(:role)
  end

  def signup_email
    signup_state.try(:contact_info_value)
  end

  def set_client_app(client_id)
    @client_app = client_id.nil? ?
                    nil :
                    Doorkeeper::Application.find_by(uid: client_id)
    session[:client_app] = @client_app.present? ? @client_app.id : nil
  end

  def get_client_app
    @client_app ||= session[:client_app].nil? ?
                      nil :
                      Doorkeeper::Application.find_by(id: session[:client_app])
  end

  # called when user arrived at app with go == 'student_signup'
  # note we're also clearning the session[:signup_role], that's important
  # so the session var doesn't stick around if user later comes from a different origin
  def set_student_signup_role(is_student)
      session[:signup_role] = is_student ? 'student' : nil
  end

  def set_alternate_signup_url(url)
    if url.blank? || !url.is_a?(String)
      session[:alt_signup] = nil
    else
      # http://stackoverflow.com/a/18355425
      # Just in case the url got encoded multiple times
      current_url, url = url, URI.decode(url) until url == current_url

      if get_client_app.try!(:is_redirect_url?, url)
        session[:alt_signup] = url
      else
        session[:alt_signup] = nil

        message = "Alternate signup URL (#{url}) is not a redirect_uri " \
                  "for client app #{get_client_app.try!(:uid)}"
        Rails.logger.warn(message)

        raise message unless Rails.env.production?
      end
    end
  end

  def get_alternate_signup_url
    session[:alt_signup]
  end

  # called when the user is redirected from a LMS
  def set_session_state_from_lms(params)
    session[:return_to] = 'https://system.showmaker.com/'
    session[:lms] = {
      email: params[:email],
      name: params[:name],
      role: params[:role] == 'instructor' ? 'instructor' : 'student'
    }
  end
end
