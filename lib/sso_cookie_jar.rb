# Creates a separate cookie jar on top of Rails' internal ones
# https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/cookies.rb
class SsoCookieJar < ActionDispatch::Cookies::AbstractCookieJar
  secrets = Rails.application.secrets.sso[:cookie]
  @@cookie_name = secrets[:name]
  @@cookie_options = secrets[:options]

  def subject
    cookie = self[@@cookie_name]
    cookie.symbolize_keys[:sub] unless cookie.nil?
  end

  def subject=(subject)
    permanent[@@cookie_name] = { value: { sub: subject } }
  end

  def delete(options = {})
    @parent_jar.delete @@cookie_name, options.reverse_merge(@@cookie_options)
  end

  def parse(name, encrypted_message, purpose: nil)
    SsoCookie.read encrypted_message
  end

  def commit(options)
    options[:value] = SsoCookie.generate options
    options.reverse_merge! @@cookie_options

    current_time = Time.current
    options[:value] = JSON::JWT.new(
      options[:value].merge(
        iss: 'OpenStax Accounts',
        aud: 'OpenStax',
        exp: (current_time + (options[:expires_in] || 20.years)).to_i,
        nbf: current_time.to_i,
        iat: current_time.to_i,
        jti: SecureRandom.uuid
      )
    ).sign(
      @signature_private_key, @signature_algorithm
    ).encrypt(
      @encryption_public_key, @encryption_algorithm.to_sym, @encryption_method.to_sym
    ).to_s

    if options[:value].bytesize > ActionDispatch::Cookies::MAX_COOKIE_SIZE
      raise CookieOverflow
    end
  end
end

ActionDispatch::Cookies::ChainedCookieJars.module_exec do
  def sso
    @sso ||= SsoCookieJar.new(self)
  end
end
