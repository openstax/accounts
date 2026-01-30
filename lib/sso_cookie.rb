module SsoCookie
  secrets = Rails.application.secrets.sso
  @signature_private_key = OpenSSL::PKey::RSA.new(secrets[:signature_private_key]) \
    rescue secrets[:signature_private_key]
  @signature_public_key = OpenSSL::PKey::RSA.new(secrets[:signature_public_key]) \
    rescue secrets[:signature_public_key]
  @signature_algorithm = secrets[:signature_algorithm]&.to_sym

  @encryption_private_key = OpenSSL::PKey::RSA.new(secrets[:encryption_private_key]) \
    rescue secrets[:encryption_private_key]
  @encryption_public_key = OpenSSL::PKey::RSA.new(secrets[:encryption_public_key]) \
    rescue secrets[:encryption_public_key]
  @encryption_algorithm = secrets[:encryption_algorithm]
  @encryption_method = secrets[:encryption_method]

  def self.user_hash(user)
    Api::V1::SsoCookieRepresenter.new(user).to_hash
  end

  # This method is used in 2 different ways:
  # Called with value: { sub: user_hash } by the SsoCookieJar
  # Called with resource_owner_id: integer by Doorkeeper
  def self.generate(options = {})
    value = options[:value] || {}

    if value[:sub].blank? && options[:resource_owner_id].present?
      value[:sub] = user_hash(User.find(options[:resource_owner_id]))
    end

    current_time = Time.current
    JSON::JWT.new(
      value.merge(
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
    ).to_s.tap do |result|
      raise CookieOverflow if result.bytesize > ActionDispatch::Cookies::MAX_COOKIE_SIZE
    end
  end

  def self.read(cookie)
    JSON::JWT.decode(
      JSON::JWT.decode(
        cookie,
        @encryption_private_key,
        @encryption_algorithm.to_s,
        @encryption_method.to_s
      ).plain_text,
      @signature_public_key,
      @signature_algorithm
    )
  rescue JSON::JWT::Exception, OpenSSL::Cipher::CipherError
    nil
  end
end
