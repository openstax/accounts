# https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/cookies.rb

# The base class in Rails 5 is EncryptedKeyRotatingCookieJar
class SsoEncryptedCookieJar < ActionDispatch::Cookies::EncryptedKeyRotatingCookieJar
  # Rails 5: def initialize(parent_jar)
  def initialize(parent_jar)
    key_generator = ActiveSupport::CachingKeyGenerator.new(
      ActiveSupport::KeyGenerator.new(Rails.application.secrets.sso[:shared_secret], iterations: 1000)
    )
    salt = Rails.application.secrets.sso[:shared_secret_salt] || 'cookie'
    options = {
      encrypted_cookie_salt: salt,
      encrypted_signed_cookie_salt: "signed encrypted #{salt}",
      serializer: :json,
      secret_key_base: Rails.application.secrets.sso[:shared_secret]
    }
    super(parent_jar, key_generator, options)
  end
end

# Provides a separate CookieJar for the SSO cookie, with a different shared_secret
class SsoCookieJar < ActionDispatch::Cookies::CookieJar
  def encrypted
    # Rails 5: @encrypted ||= SsoEncryptedCookieJar.new(self)
    @encrypted ||= SsoEncryptedCookieJar.new(self)
  end
end

ActionDispatch::Request.class_exec do
  # Rails 4:
  # def have_cookie_jar?
  #   env.key? 'action_dispatch.cookies'.freeze
  # end

  # def have_sso_cookie_jar?
  #   env.key? 'action_dispatch.sso_cookies'.freeze
  # end

  # def sso_cookie_jar
  #   env['action_dispatch.sso_cookies'.freeze] ||= SsoCookieJar.build(self)
  # end

  # Rails 5:
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
