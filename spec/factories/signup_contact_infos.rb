FactoryGirl.define do
  factory :signup_contact_info do
    kind :email_address
    value "#{SecureRandom.hex(4)}@#{SecureRandom.hex(4)}.com"
    confirmation_sent_at { Time.now }

    trait :verified do
      after(:create) do |sci, evaluator|
        sci.verified = true
        sci.confirmation_code = nil
        sci.confirmation_pin = nil
        sci.save
      end
    end
  end
end
