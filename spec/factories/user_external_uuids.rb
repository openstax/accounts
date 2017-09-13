FactoryGirl.define do
  factory :user_external_uuid do
    user
    uuid { SecureRandom.uuid }
  end
end
