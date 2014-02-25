class Identity < OmniAuth::Identity::Models::ActiveRecord
  belongs_to :user
  
  validates :password, presence: true, 
                       length: {minimum: 8, maximum: 40}

  attr_accessible :password_digest, :password, :password_confirmation, :user_id

  def authenticate unencrypted_password
    if is_password_digest_ssha?
      authenticate_with_ssha unencrypted_password
    else
      super
    end
  end

  protected
  def is_password_digest_ssha?
    self.password_digest.start_with? '{SSHA}'
  end

  def authenticate_with_ssha unencrypted_password
    _, password_digest = self.password_digest.split('}', 2)
    salt = Base64::decode64(password_digest)[20..-1]
    sha_digest = Digest::SHA1.digest(unencrypted_password + salt)
    if Base64::encode64(sha_digest + salt)[0..-2] == password_digest
      self
    else
      false
    end
  end
end
