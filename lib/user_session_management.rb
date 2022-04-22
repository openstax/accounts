require 'oauth2'

# References:
#   http://railscasts.com/episodes/356-dangers-of-session-hijacking

# This module must be included into a controller to work properly
module UserSessionManagement
  def cookie_jar
    @cookie_jar ||= if respond_to?(:cookies, true)
      cookies
    elsif request.respond_to?(:cookie_jar)
      request.cookie_jar
    else
      ActionDispatch::Cookies::CookieJar.build(
        ActionDispatch::Request.new(Rails.application.env_config), request.cookies
      )
    end
  end

  def sso_cookie_jar
    SsoCookieJar.new cookie_jar
  end

  # Always return an object
  def current_user
    # The SSO cookie has sole responsibility for managing the current user
    @current_user ||= begin
      user_hash = sso_cookie_jar.subject
      current_sso_user = User.find_by(uuid: user_hash['uuid']) if user_hash.present?

      if current_sso_user.nil?
        AnonymousUser.instance
      else
        # Some users may not have the new SSO cookie yet, so set it
        sso_cookie_jar.subject = user_hash if sso_cookie_jar.subject.blank?
        current_sso_user
      end
    end
  end

  def sign_in!(user, log: true, security_log_data: {})
    @current_user = user || AnonymousUser.instance

    if @current_user.is_anonymous?
      # Clear the SSO cookie
      sso_cookie_jar.delete

      security_log(:sign_out, security_log_data) if log
    else
      session[:last_admin_activity] = DateTime.now.to_s if @current_user.is_administrator?

      # Set the SSO cookie
      user_hash = Api::V1::UserRepresenter.new(@current_user).to_hash
      sso_cookie_jar.subject = user_hash

      security_log(:sign_in_successful, security_log_data) if log
    end

    @current_user
  end

  def sign_out!(options={})
    clear_signup_state
    clear_incomplete_educator

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

  def set_alternate_signup_url(url)
    if url.blank? || !url.is_a?(String)
      session[:alt_signup] = nil
    else
      # http://stackoverflow.com/a/18355425
      # Just in case the url got encoded multiple times
      current_url, url = url, Addressable::URI.unencode(url) until url == current_url

      if get_client_app&.is_redirect_url?(url)
        url = Addressable::URI.parse(url)
        url.query_values = url&.query_values
        session[:alt_signup] = url.to_s
      else
        session[:alt_signup] = nil

        message = "Alternate signup URL (#{url}) is not a redirect_uri " \
                  "for client app #{get_client_app&.uid}"
        Rails.logger.warn(message)

        raise message unless Rails.env.production?
      end
    end
  end

  def get_alternate_signup_url
    session[:alt_signup]
  end

  # New flow below

  def save_unverified_user(user_id)
    session[:unverified_user_id] = user_id
  end

  def unverified_user
    byebug
    id = session[:unverified_user_id]&.to_i
    return if id.blank?

    unverified_user ||= User.find_by(id: id)
  end

  def clear_unverified_user
    session.delete(:unverified_user_id)
  end

  def clear_login_failed_email
    session.delete(:login_failed_email)
  end

  def clear_signup_state
    clear_login_failed_email
    clear_unverified_user
  end

  def save_login_failed_email(email)
    session[:login_failed_email] = email
  end

  def login_failed_email
    session.delete(:login_failed_email)
  end

  def save_incomplete_educator(user)
    session[:current_incomplete_educator_uuid] = user.uuid
  end

  def current_incomplete_educator
    return if session[:current_incomplete_educator_uuid].blank?
    @current_incomplete_educator ||= User.find_by(uuid: session[:current_incomplete_educator_uuid])
  end

  def clear_incomplete_educator
    session.delete(:current_incomplete_educator_uuid)
  end

end
