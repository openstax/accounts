class MessageContactInfo < ActiveRecord::Base
  belongs_to :message, inverse_of: :message_contact_infos
  belongs_to :contact_info, inverse_of: :message_contact_infos

  validates :message, presence: true
  validates :contact_info, presence: true, uniqueness: {scope: :message_id}
end
