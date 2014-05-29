FactoryGirl.define do
  factory :message_recipient do
    message
    contact_info
    user { contact_info.user }
    recipient_type 'to'
  end
end
