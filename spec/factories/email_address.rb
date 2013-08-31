FactoryGirl.define do
  factory :email_address, class: EmailAddress, parent: :contact_info do |contact_info|
    contact_info.value { "#{SecureRandom.hex(2)}@#{SecureRandom.hex(2)}.com" }
    contact_info.type "EmailAddress"
  end
end

