FactoryGirl.define do
  factory :message_recipient do
    message
    association :contact_info, factory: :email_address
    user { contact_info.user }
    recipient_type 'to'
  end
end
