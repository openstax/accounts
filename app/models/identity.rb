class Identity < OmniAuth::Identity::Models::ActiveRecord

  DEFAULT_PASSWORD_EXPIRATION_PERIOD = \
    Rails.configuration.accounts.default_password_expiration_period

  MIN_PASSWORD_LENGTH = 8

  belongs_to :user, inverse_of: :identity

  # We need these validations because
  # omniauth-identity does not provide them by default
  # The password is hashed (BCrypt) before being saved in the database
  validates :password, presence: true, length: { minimum: MIN_PASSWORD_LENGTH, maximum: 50 }
  validates :user_id, uniqueness: true

  # Support for legacy CNX passwords
  def authenticate(unencrypted_password)
    if is_password_digest_ssha?
      authenticate_with_ssha unencrypted_password
    else
      super
    end
  end

  # Returns true if the user is due for resetting their password
  def password_expired?
    !password_expires_at.nil? && password_expires_at <= DateTime.now
  end

  protected

  # Support for legacy CNX passwords
  def is_password_digest_ssha?
    password_digest.start_with? '{SSHA}'
  end

  # Support for legacy CNX passwords
  def authenticate_with_ssha(unencrypted_password)
    # This code is originally in python, Plone 2.5
    # from AccessControl.AuthEncoding.SSHADigestScheme.validate
    #
    # def validate(self, reference, attempt):
    #     try:
    #         ref = a2b_base64(reference)
    #     except binascii.Error:
    #         # Not valid base64.
    #         return 0
    #     salt = ref[20:]
    #     compare = b2a_base64(sha.new(attempt + salt).digest() + salt)[:-1]
    #     return (compare == reference)
    #
    p_digest = password_digest[6..-1]
    salt = Base64::decode64(p_digest)[20..-1]
    return false if salt.nil?
    sha_digest = Digest::SHA1.digest(unencrypted_password + salt)
    if Base64::encode64(sha_digest + salt)[0..-2] == p_digest
      self
    else
      false
    end
  end
end
