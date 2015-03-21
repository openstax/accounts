FactoryGirl.define do
  factory :authentication do
    provider { OmniauthData::VALID_PROVIDERS.sample }
    uid { SecureRandom.hex(3) }
    user
  end  
end