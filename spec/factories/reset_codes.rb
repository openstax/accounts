# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :reset_code do
    identity
    code { SecureRandom.hex(16) }
    expires_at { Time.now + 1.week }
  end
end
