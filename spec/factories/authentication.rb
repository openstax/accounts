FactoryGirl.define do
  factory :authentication do
    provider { OmniauthData::VALID_PROVIDERS.sample }
    uid { SecureRandom.hex(3) }

    factory :authentication_with_user do
      user
    end
  end  
end