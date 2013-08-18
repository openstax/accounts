FactoryGirl.define do
  factory :authentication do
    provider { SecureRandom.hex(3) }
    uid { SecureRandom.hex(3) }
  end  
end