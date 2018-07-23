FactoryGirl.define do
  factory :banner do
    message "This is a banner."
    expires_at DateTime.now + 1.day
  end
end
