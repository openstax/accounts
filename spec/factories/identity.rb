FactoryGirl.define do

  factory :identity do
    association :user, :factory => :temp_user
    password { SecureRandom.hex(8) }
    password_confirmation { password }
  end

end
