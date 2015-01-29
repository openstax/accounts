class ResetCode < ActiveRecord::Base

  DEFAULT_EXPIRATION_PERIOD = \
    Rails.configuration.accounts.default_reset_code_expiration_period

  belongs_to :identity, inverse_of: :reset_code

  validates :identity, presence: true
  validates :identity_id, uniqueness: true
  validates :code, presence: true, uniqueness: true

  def generate(expiration_period = DEFAULT_EXPIRATION_PERIOD)
    self.code = SecureRandom.hex(16)
    self.expires_at = expiration_period.nil? ? nil : \
                                               DateTime.now + expiration_period
  end

  def expire
    self.expires_at = DateTime.now
  end

  # Returns true if the code is present in the DB and hasn't expired
  def expired?
    !expires_at.nil? && expires_at <= DateTime.now
  end

end
