FactoryBot.define do
  factory :pre_auth_state do
    contact_info_kind { :email_address }
    contact_info_value { "#{SecureRandom.hex(4)}@#{SecureRandom.hex(4)}.com" }
    confirmation_sent_at { Time.now }
    role { "instructor" }

    trait :signed do
      signed_data {
        {
          external_user_uuid: SecureRandom.uuid,
          name: Faker::Name.name,
          email: Faker::Internet.email,
        }
      }
    end

    trait :contact_info_verified do
      after(:create) do |ss, evaluator|
        ss.is_contact_info_verified = true
        ss.confirmation_code = nil
        ss.confirmation_pin = nil
        ss.save
      end
    end
  end
end
