class ContactInfo < ActiveRecord::Base
  belongs_to :user

  attr_accessible :confirmation_code, :type, :user_id, :value, :verified

  validates :value, 
            presence: true,
            uniqueness: {scope: [:user_id, :type]}

  scope :email_addresses, where(type: 'EmailAddress')
end
