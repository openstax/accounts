FactoryBot.define do
  factory :email_address, class: EmailAddress, parent: :contact_info do |contact_info|
    contact_info.value {
      "#{SecureRandom.hex(3)}@#{EmailAddress::WHITELIST.sample}"
    }

    contact_info.type { "EmailAddress" }
  end
end
