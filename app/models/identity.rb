class Identity < OmniAuth::Identity::Models::ActiveRecord

  belongs_to :user, inverse_of: :identity

  auth_key :user_id
  # We need these validations because
  # omniauth-identity does not provide them by default
  # The password is hashed (BCrypt) before being saved in the database
  validates :password, presence: true, length: { minimum: 8, maximum: 50 }
  validates :user_id, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex

  # Returns true if the user is due for resetting their password
  def password_expired?
    !password_expires_at.nil? && password_expires_at <= DateTime.now
  end
end
