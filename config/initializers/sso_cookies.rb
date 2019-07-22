# https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/cookies.rb

# The base class in Rails 5 is EncryptedKeyRotatingCookieJar
class SsoEncryptedCookieJar < ActionDispatch::Cookies::EncryptedKeyRotatingCookieJar
  def initialize(parent_jar)
    super

    key_generator = ActiveSupport::CachingKeyGenerator.new(
      ActiveSupport::KeyGenerator.new(Rails.application.secrets.sso[:shared_secret], iterations: 1000)
    )
    salt = Rails.application.secrets.sso[:shared_secret_salt] || 'cookie'

    key_len = ActiveSupport::MessageEncryptor.key_len("aes-256-cbc")
    encrypted_signed_cookie_salt = "signed encrypted #{salt}"

    secret = key_generator.generate_key(salt, key_len)
    sign_secret = key_generator.generate_key(encrypted_signed_cookie_salt)
    # @encryptor = ActiveSupport::MessageEncryptor.new(secret, sign_secret, cipher: "aes-256-cbc", serializer: JsonSerializer) # BRYAN - https://github.com/rails/rails/blob/98a57aa5f610bc66af31af409c72173cdeeb3c9e/actionpack/lib/action_dispatch/middleware/cookies.rb#L505
    @encryptor = ActiveSupport::MessageEncryptor.new(secret, sign_secret, cipher: "aes-256-cbc", serializer: JSON)
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
