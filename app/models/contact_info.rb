class ContactInfo < ActiveRecord::Base
  belongs_to :user

  attr_accessible :confirmation_code, :type, :user_id, :value, :verified
end
