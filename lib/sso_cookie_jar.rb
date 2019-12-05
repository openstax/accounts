# Creates a separate cookie jar on top of Rails' internal ones
# https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/cookies.rb
class SsoCookieJar < ActionDispatch::Cookies::AbstractCookieJar
  def initialize(parent_jar)
    super

    secrets = Rails.application.secrets.sso
    @signature_private_key = OpenSSL::PKey::RSA.new secrets[:signature_private_key]
    @signature_public_key = OpenSSL::PKey::RSA.new secrets[:signature_public_key]
    @signature_algorithm = secrets[:signature_algorithm].to_sym

    @encryption_private_key = OpenSSL::PKey::RSA.new(secrets[:encryption_private_key]) \
      rescue secrets[:encryption_private_key]
    @encryption_public_key = OpenSSL::PKey::RSA.new(secrets[:encryption_public_key]) \
      rescue secrets[:encryption_public_key]
    @encryption_algorithm = secrets[:encryption_algorithm]
    @encryption_method = secrets[:encryption_method]

    cookie_secrets = secrets[:cookie]
    @cookie_name = cookie_secrets[:name]
    @cookie_options = cookie_secrets[:options]
  end

  def subject
    cookie = self[@cookie_name]
    cookie.symbolize_keys[:sub] unless cookie.nil?
  end

  def subject=(subject)
    permanent[@cookie_name] = { value: { sub: subject } }
  end

  def delete(options = {})
    @parent_jar.delete @cookie_name, options.reverse_merge(@cookie_options)
  end

  private

  def parse(name, encrypted_message, purpose: nil)
    JSON::JWT.decode(
      JSON::JWT.decode(
        encrypted_message,
        @encryption_private_key,
        @encryption_algorithm.to_s,
        @encryption_method.to_s
      ).plain_text, @signature_public_key, @signature_algorithm
    )
  rescue JSON::JWT::Exception, OpenSSL::Cipher::CipherError
    nil
  end

  def commit(options)
    options.reverse_merge! @cookie_options

    current_time = Time.current
    options[:value] = JSON::JWT.new(
      options[:value].merge(
        iss: 'OpenStax Accounts',
        aud: 'OpenStax',
        exp: (current_time + 20.years).to_i,
        nbf: current_time.to_i,
        iat: current_time.to_i,
        jti: SecureRandom.uuid
      )
    ).sign(@signature_private_key, @signature_algorithm)
     .encrypt(@encryption_public_key, @encryption_algorithm.to_sym, @encryption_method.to_sym).to_s

    raise CookieOverflow if options[:value].bytesize > ActionDispatch::Cookies::MAX_COOKIE_SIZE
  end
end

ActionDispatch::Cookies::ChainedCookieJars.module_exec do
  def sso
    @sso ||= SsoCookieJar.new(self)
  end
end
