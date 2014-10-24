FactoryGirl.define do
  factory :email_address, class: EmailAddress, parent: :contact_info do |contact_info|
    contact_info.value {
      "#{SecureRandom.hex(3)}@#{SecureRandom.hex(3)}.#{SecureRandom.hex(3)}" }
    contact_info.type "EmailAddress"
  end
end

