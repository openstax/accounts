class ContactInfo < ActiveRecord::Base
  VALID_TYPES = ['EmailAddress']

  belongs_to :user, inverse_of: :contact_infos

  has_many :application_users, foreign_key: :default_contact_info_id
  has_many :message_recipients, inverse_of: :contact_info

  attr_accessible :type, :value

  before_validation :strip

  validates :user, presence: true
  validates :type, presence: true, inclusion: { in: VALID_TYPES }
  validates :value,
            presence: true,
            uniqueness: {scope: [:user_id, :type]}

  scope :email_addresses, where(type: 'EmailAddress')
  sifter :email_addresses do type.eq 'EmailAddress' end

  scope :verified, where(verified: true)
  sifter :verified do verified.eq true end

  scope :with_users, lambda { includes(:user) }

  before_save :add_unread_update

  def to_subclass
    return self unless valid?
    becomes(type.constantize)
  end

  def add_unread_update
    user.add_unread_update
  end

  protected

  def strip
    self.value = self.value.try(:strip)
  end
end
