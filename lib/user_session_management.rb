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

  def sign_in!(user, security_log_data: {})
    @current_user = user || AnonymousUser.instance

    if @current_user.is_anonymous?
      # Clear the SSO cookie
      sso_cookie_jar.delete

      security_log(:sign_out, security_log_data)
    else
      session[:last_admin_activity] = DateTime.now.to_s if @current_user.is_administrator?

      # Set the SSO cookie
      user_hash = Api::V1::UserRepresenter.new(@current_user).to_hash
      sso_cookie_jar.subject = user_hash

      security_log :sign_in_successful, security_log_data
    end

    @current_user
  end

  def sign_out!(options={})
    clear_login_state
    sign_in!(AnonymousUser.instance, options)
  end

  def signed_in?
    !current_user.is_anonymous?
  end

  def set_login_state(email: nil, first_name: nil, last_name: nil, role: nil)
    session[:login] = {
      'email' => email,
      'first_name' => first_name,
      'last_name' => last_name,
      'role' => role
    }
  end

  def get_login_state
    {
      email: session[:login].try(:[],'email'),
      first_name: session[:login].try(:[], 'first_name'),
      last_name: session[:login].try(:[],'last_name'),
      role: session[:login].try(:[], 'role'),
    }
  end

  def clear_login_state
    session.delete(:login)
  end

  def set_client_app(client_id)
    @client_app = client_id.nil? ? nil : Doorkeeper::Application.find_by(uid: client_id)
    session[:client_app] = @client_app.present? ? @client_app.id : nil
  end

  def get_client_app
    @client_app ||= session[:client_app].nil? ? nil : Doorkeeper::Application.find_by(id: session[:client_app])
  end

  def set_alternate_signup_url(url)
    if url.blank? || !url.is_a?(String)
      session[:alt_signup] = nil
    else
      # http://stackoverflow.com/a/18355425
      # Just in case the url got encoded multiple times
      current_url, url = url, Addressable::URI.unencode(url) until url == current_url

      if get_client_app.try!(:is_redirect_url?, url)
        url = Addressable::URI.parse(url)
        url.query_values = url&.query_values
        session[:alt_signup] = url.to_s
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
