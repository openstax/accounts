FactoryGirl.define do
  factory :signup_state do
    contact_info_kind :email_address
    contact_info_value "#{SecureRandom.hex(4)}@#{SecureRandom.hex(4)}.com"
    confirmation_sent_at { Time.now }
    role "instructor"

    trait :trusted do
      trusted_data {
        {
          uuid: SecureRandom.uuid,
          name: Faker::Name.name,
          email: Faker::Internet.email,
        }
      }
    end

    trait :verified do
      after(:create) do |ss, evaluator|
        ss.verified = true
        ss.confirmation_code = nil
        ss.confirmation_pin = nil
        ss.save
      end
    end
  end
end
