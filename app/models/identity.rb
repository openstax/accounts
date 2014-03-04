class Identity < OmniAuth::Identity::Models::ActiveRecord
  belongs_to :user
  
  validates :password, presence: true, 
                       length: {minimum: 8, maximum: 40}

  attr_accessible :password_digest, :password, :password_confirmation, :user_id

  DEFAULT_RESET_CODE_EXPIRATION_PERIOD = 2.days

  def authenticate unencrypted_password
    if is_password_digest_ssha?
      authenticate_with_ssha unencrypted_password
    else
      super
    end
  end

  def generate_reset_code(expiration_period=DEFAULT_RESET_CODE_EXPIRATION_PERIOD)
    self.reset_code = SecureRandom.hex(16)
    if !expiration_period.nil?
      self.reset_code_expires_at = DateTime.now + expiration_period
    else
      self.reset_code_expires_at = nil
    end
  end

  def use_reset_code(code)
    if self.reset_code == code && DateTime.now <= self.reset_code_expires_at
      self.reset_code = nil
      self.reset_code_expires_at = nil
      true
    else
      false
    end
  end

  protected
  def reset_code=(code)
    update_column :reset_code, code
  end

  def reset_code_expires_at=(expiration_time)
    update_column :reset_code_expires_at, expiration_time
  end

  def is_password_digest_ssha?
    self.password_digest.start_with? '{SSHA}'
  end

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
