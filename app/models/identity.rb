class Identity < OmniAuth::Identity::Models::ActiveRecord

  DEFAULT_PASSWORD_EXPIRATION_PERIOD = Rails.configuration.accounts.default_password_expiration_period

  MIN_PASSWORD_LENGTH = 8

  belongs_to :user, inverse_of: :identity

  # We need these validations because
  # omniauth-identity does not provide them by default
  # The password is hashed (BCrypt) before being saved in the database
  validates :password, presence: true, length: { minimum: MIN_PASSWORD_LENGTH, maximum: 50 }
  validates :user, presence: true
  validates :user_id, uniqueness: true

  # Returns true if the user is due for resetting their password
  def password_expired?
    # TODO: In another PR, remove this line and make a data migration to set all expiration timestamps to null
    return if DEFAULT_PASSWORD_EXPIRATION_PERIOD.nil?
    !password_expires_at.nil? && password_expires_at <= DateTime.now
  end
end
