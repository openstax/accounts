class Identity < OmniAuth::Identity::Models::ActiveRecord
  belongs_to :user, inverse_of: :identity

  attr_accessible :password, :password_confirmation

  # We need these validations because omniauth-identity does not
  # provide them by default...
  validates :password, presence: true,
                       length: {minimum: 8, maximum: 40}
  validates :password_confirmation, presence: true

  before_save :update_password_expires_at, if: :password_changed?

  DEFAULT_RESET_CODE_EXPIRATION_PERIOD = Rails.configuration.accounts.default_reset_code_expiration_period
  DEFAULT_PASSWORD_EXPIRATION_PERIOD = Rails.configuration.accounts.default_password_expiration_period

  # Support for legacy CNX passwords
  def authenticate unencrypted_password
    if is_password_digest_ssha?
      authenticate_with_ssha unencrypted_password
    else
      super
    end
  end

  # Generates a reset code (and saves the identity without validation)
  def generate_reset_code!(expiration_period=DEFAULT_RESET_CODE_EXPIRATION_PERIOD)
    self.reset_code = SecureRandom.hex(16)
    if !expiration_period.nil?
      self.reset_code_expires_at = DateTime.now + expiration_period
    else
      self.reset_code_expires_at = nil
    end
    self.save!(validate: false)
    self.reset_code
  end

  # Returns true iff the code is valid and matches
  def reset_code_valid?(code)
    return true if self.reset_code == code && \
                     (self.reset_code_expires_at.nil? || \
                     self.reset_code_expires_at >= DateTime.now)
    false
  end

  # Sets the password (and saves the identity)
  def set_password!(password, password_confirmation)
    # Always invalidate reset codes when the password changes
    self.reset_code = nil
    self.reset_code_expires_at = nil

    self.password = password
    self.password_confirmation = password_confirmation
    self.save
  end

  def should_reset_password?
    self.password_expires_at && self.password_expires_at < DateTime.now
  end

  protected

  def reset_code=(code)
    super
  end

  def reset_code_expires_at=(expiration_period)
    super
  end

  def password_changed?
    password_digest_changed?
  end

  # Called when the password is changed to set a new expiration date
  def update_password_expires_at
    if DEFAULT_PASSWORD_EXPIRATION_PERIOD.nil?
      self.password_expires_at = nil
    else
      self.password_expires_at = DateTime.now + DEFAULT_PASSWORD_EXPIRATION_PERIOD
    end
    true
  end

  # Support for legacy CNX passwords
  def is_password_digest_ssha?
    self.password_digest.start_with? '{SSHA}'
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
    _, password_digest = self.password_digest.split('}', 2)
    salt = Base64::decode64(password_digest)[20..-1]
    return false if salt.nil?
    sha_digest = Digest::SHA1.digest(unencrypted_password + salt)
    if Base64::encode64(sha_digest + salt)[0..-2] == password_digest
      self
    else
      false
    end
  end
end
