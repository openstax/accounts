class Banner < ActiveRecord::Base
  scope :active, -> { where('expires_at > ?', DateTime.now) }

  validates :message, presence: true
  validates :expires_at, presence: true

  def expires_at=(expires_at)
    super(expires_at).try(:in_time_zone, 'Central Time (US & Canada)')
  end
end
