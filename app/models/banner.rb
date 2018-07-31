class Banner < ActiveRecord::Base
  TIME_ZONE = 'Central Time (US & Canada)'

  scope :active, -> { where('expires_at > ?', DateTime.now) }

  validates :message, presence: true
  validates :expires_at, presence: true

  def expires_at=(expires_at)
    with_time_zone = ActiveSupport::TimeZone[TIME_ZONE].parse(expires_at.to_s)
    super(with_time_zone)
  end
end
