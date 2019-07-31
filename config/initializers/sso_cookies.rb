# https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/cookies.rb

Rails.application.configure do
  config.action_dispatch.use_authenticated_cookie_encryption = false
  config.action_dispatch.use_authenticated_message_encryption = false
  config.active_support.use_authenticated_message_encryption = false

  salt = Rails.application.secrets.sso[:shared_secret_salt] || 'cookie'
  config.action_dispatch.encrypted_cookie_salt = salt
  config.action_dispatch.encrypted_signed_cookie_salt = "signed encrypted #{salt}"

  config.action_dispatch.cookies_serializer = ActionDispatch::Cookies::JsonSerializer
end

class SsoEncryptedCookieJar < ActionDispatch::Cookies::EncryptedKeyRotatingCookieJar
  def initialize(parent_jar)
    super
  end
end

# Provides a separate CookieJar for the SSO cookie, with a different shared_secret
class SsoCookieJar < ActionDispatch::Cookies::CookieJar
  def encrypted
    @encrypted ||= SsoEncryptedCookieJar.new(self)
  end
end

ActionDispatch::Request.class_exec do
  def have_sso_cookie_jar?
   has_header? 'action_dispatch.sso_cookies'.freeze
  end

  def sso_cookie_jar=(jar)
   set_header 'action_dispatch.sso_cookies'.freeze, jar
  end

  def sso_cookie_jar
   fetch_header('action_dispatch.sso_cookies'.freeze) do
     self.sso_cookie_jar = SsoCookieJar.build(self, cookies)
   end
  end
end

ActionDispatch::Cookies.class_exec do
  def call(env)
    request = ActionDispatch::Request.new env

    status, headers, body = @app.call(env)

    if request.have_cookie_jar?
      cookie_jar = request.cookie_jar
      cookie_jar.write(headers) unless cookie_jar.committed?
    end

    if request.have_sso_cookie_jar?
      cookie_jar = request.sso_cookie_jar
      cookie_jar.write(headers) unless cookie_jar.committed?
    end

    if headers[ActionDispatch::Cookies::HTTP_HEADER].respond_to?(:join)
      headers[ActionDispatch::Cookies::HTTP_HEADER] =
        headers[ActionDispatch::Cookies::HTTP_HEADER].join("\n")
    end

    [status, headers, body]
  end
end
