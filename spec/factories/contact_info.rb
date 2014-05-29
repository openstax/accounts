FactoryGirl.define do
  factory :contact_info do
    user
    value { "#{SecureRandom.hex(4)}" }
  end
end
