class ContactInfo < ActiveRecord::Base
  belongs_to :user, inverse_of: :contact_infos

  has_many :application_users, foreign_key: :default_contact_info_id
  has_many :message_recipients, inverse_of: :contact_info

  attr_accessible :confirmation_code, :type, :user_id, :value, :verified

  validates :user, presence: true
  validates :value,
            presence: true,
            uniqueness: {scope: [:type]}

  scope :email_addresses, where(type: 'EmailAddress')
  sifter :email_addresses do type.eq 'EmailAddress' end

  scope :verified, where(verified: true)
  sifter :verified do verified.eq true end

  scope :with_users, lambda { includes(:user) }

  before_save :add_unread_update

  def add_unread_update
    user.add_unread_update
  end
end
