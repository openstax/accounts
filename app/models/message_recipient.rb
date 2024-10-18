class MessageRecipient < ApplicationRecord
  belongs_to :message, inverse_of: :message_recipients
  belongs_to :contact_info, inverse_of: :message_recipients
  belongs_to :user, optional: true, inverse_of: :message_recipients

  validates :message, presence: true
  validates_uniqueness_of :contact_info_id, scope: :message_id,
                          allow_nil: true, if: :message_id
  validates_uniqueness_of :user_id, scope: :message_id,
                          allow_nil: true, if: :message_id

  def value
    contact_info.try(:value)
  end
end
