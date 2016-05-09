FactoryGirl.define do
  factory :security_log do
    user
    application nil
    remote_ip '127.0.0.1'
    event_type :unspecified
    event_data { {} }
  end
end
