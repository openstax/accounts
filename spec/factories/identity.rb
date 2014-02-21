FactoryGirl.define do

  factory :identity do
    user
    password { SecureRandom.hex(8) }
  end

end
