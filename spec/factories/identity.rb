FactoryBot.define do

  factory :identity do
    association :user
    password { SecureRandom.hex(8) }
  end

end
