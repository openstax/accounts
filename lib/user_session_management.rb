require 'oauth'

# This module must be included into a controller to work properly
module UserSessionManagement

  # References:
  #   http://railscasts.com/episodes/356-dangers-of-session-hijacking

  def sso_cookie_secrets
    Rails.application.secrets.sso['cookie']
  end

  # Always return an object
  def current_session_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    @current_user ||= AnonymousUser.instance
  end

  def current_sso_user
    return @current_sso_user unless @current_sso_user.nil?

    cookie_name = sso_cookie_secrets['name']
    cookie = sso_cookies.encrypted[cookie_name]
    @current_sso_user = User.find_by(uuid: cookie.dig('user', 'uuid')) if cookie.present?
    @current_sso_user ||= AnonymousUser.instance
  end

  alias_method :current_user, :current_session_user

  def allow_sso_user!
    @current_user = current_sso_user if current_session_user.is_anonymous?
  end

  def sign_in!(user, options={})
    options[:security_log_data] ||= {}

    session[:client_id] = nil
    session[:alt_signup] = nil

    clear_login_state
    @current_user = user || AnonymousUser.instance

    if @current_user.is_anonymous?
      session[:user_id] = nil

      # Clear the SSO cookie
      sso_cookies.delete(sso_cookie_secrets['name'], domain: sso_cookie_secrets['options']['domain'])

      security_log :sign_out, options[:security_log_data]
    else
      session[:user_id] = @current_user.id
      session[:last_admin_activity] = DateTime.now.to_s \
        if @current_user.is_administrator?

      # Set the SSO cookie
      request.sso_cookie_jar.encrypted[sso_cookie_secrets['name']] = {
        value: { user: Api::V1::UserRepresenter.new(current_user).to_hash }
      }.merge(sso_cookie_secrets['options'].deep_symbolize_keys)

      security_log :sign_in_successful, options[:security_log_data]
    end

    @current_user
  end

  def sign_out!(options={})
    clear_pre_auth_state

    sign_in!(AnonymousUser.instance, options)
  end

  def signed_in?
    !current_user.is_anonymous?
  end

  def set_login_state(username_or_email: nil, matching_user_ids: nil, names: nil, providers: nil)
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

  def save_pre_auth_state(pre_auth_state)
    clear_login_state
    # There may be an old signup state object around, check for that
    clear_pre_auth_state if pre_auth_state.id != session[:signup]
    session[:signup] = pre_auth_state.id
  end

  def clear_pre_auth_state
    pre_auth_state.try(:destroy)
    @pre_auth_state = nil
    session.delete(:signup)
  end

  def pre_auth_state
    id = session[:signup].to_i rescue nil
    @pre_auth_state ||= PreAuthState.find_by(id: id)
  end

  def signup_role
    pre_auth_state.try(:role)
  end

  def signup_email
    pre_auth_state.try(:contact_info_value)
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

end
