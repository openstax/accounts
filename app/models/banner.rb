class Banner < ActiveRecord::Base
  TIME_ZONE = 'Central Time (US & Canada)'

  scope :active, -> { where('expires_at > ?', DateTime.now) }

  validates :message, presence: true
  validates :expires_at, presence: true

  def active_until
    self.expires_at.strftime("%m/%d/%Y %I:%M%p")
  end
end
