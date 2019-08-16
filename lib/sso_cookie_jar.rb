# Creates a separate cookie jar on top of Rails' internal ones
# ... magically because Rails doesn't really provide a way to do so.
# https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/cookies.rb
class SsoCookieJar < ActionDispatch::Cookies::EncryptedKeyRotatingCookieJar
  def initialize(parent_jar)
    super

    secrets = Rails.application.secrets.sso

    key_generator = ActiveSupport::CachingKeyGenerator.new(
      ActiveSupport::KeyGenerator.new(
        secrets[:shared_secret], iterations: secrets.fetch(:iterations, 1000)
      )
    )
    salt = secrets[:shared_secret_salt]
    cipher = secrets.fetch(:cipher, 'aes-256-cbc')

    @encryptor = ActiveSupport::MessageEncryptor.new(
      key_generator.generate_key(salt, OpenSSL::Cipher.new(cipher).key_len),
      key_generator.generate_key("signed encrypted #{salt}"),
      cipher: cipher, serializer: ActiveSupport::MessageEncryptor::NullSerializer
    )
  end

  def delete(name, options = {})
    @parent_jar.delete name, options.reverse_merge(sso_cookie_options)
  end

  private

  def sso_cookie_options
    Rails.application.secrets.sso[:cookie][:options]
  end

  def commit(options)
    options.reverse_merge! sso_cookie_options

    super
  end
end

ActionDispatch::Cookies::ChainedCookieJars.module_exec do
  def sso
    @sso ||= SsoCookieJar.new(self)
  end
end
