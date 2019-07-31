# Creates a separate cookie jar on top of Rails' internal ones
# ... magically because Rails doesn't really provide a way to do so.
# https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/cookies.rb

# Rails.application.configure do
#   config.action_dispatch.use_authenticated_cookie_encryption = false
#   config.action_dispatch.use_authenticated_message_encryption = false
#   config.active_support.use_authenticated_message_encryption = false

#   salt = Rails.application.secrets.sso[:shared_secret_salt] || 'cookie'
#   config.action_dispatch.encrypted_cookie_salt = salt
#   config.action_dispatch.encrypted_signed_cookie_salt = "signed encrypted #{salt}"

#   config.action_dispatch.cookies_serializer = ActionDispatch::Cookies::JsonSerializer
# end

# Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = false

# Rails.application.config.active_support.use_authenticated_message_encryption = false

Rails.application.config.action_dispatch.cookies_serializer = ActionDispatch::Cookies::JsonSerializer
# Rails.application.config.action_dispatch.cookies_serializer = ActiveSupport::MessageEncryptor::NullSerializer
Rails.application.config.action_dispatch.encrypted_cookie_cipher = 'aes-256-cbc'



Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = false

class SsoEncryptedCookieJar < ActionDispatch::Cookies::EncryptedKeyRotatingCookieJar
  def initialize(parent_jar)
    @parent_jar = parent_jar

    super

    sso_shared_secret = Rails.application.secrets.sso[:shared_secret]
    sso_shared_salt = Rails.application.secrets.sso[:shared_secret_salt]
    sso_signed_salt = "signed encrypted #{sso_shared_salt}"

    key_length = OpenSSL::Cipher.new('aes-256-cbc').key_len

    sso_keygen = ActiveSupport::CachingKeyGenerator.new(
      ActiveSupport::KeyGenerator.new(sso_shared_secret, iterations: 1000)
    )
    secret = sso_keygen.generate_key(sso_shared_salt)[0, key_length]
    sign_secret = sso_keygen.generate_key(sso_signed_salt)

    json_serializer = ActionDispatch::Cookies::JsonSerializer
    sso_encryptor = ActiveSupport::MessageEncryptor.new(secret, sign_secret, serializer: json_serializer)

    self.instance_variable_set(:@encryptor, sso_encryptor)
  end
end

# Provides a separate CookieJar for the SSO cookie, with a different shared_secret
class SsoCookieJar < ActionDispatch::Cookies::CookieJar
  def encrypted
    @encrypted = SsoEncryptedCookieJar.new(self)
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

  # def encrypted_cookie_cipher
  # should probably set the Rails config instead
  #   'aes-256-cbc'
  # end
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
