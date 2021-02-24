class Banner < ApplicationRecord
  TIME_ZONE = 'Central Time (US & Canada)'

  scope :active, -> { where('expires_at > ?', DateTime.now) }

  validates :message, presence: true
  validates :expires_at, presence: true
  validate :in_future

  def in_future
    return if expires_at.nil? || expires_at > Time.now
    errors.add(:base, 'Active Until must be a future time')
  end

  def active_until
    expires_at.in_time_zone(TIME_ZONE).strftime("%m/%d/%Y %I:%M%p %Z")
  end
end
