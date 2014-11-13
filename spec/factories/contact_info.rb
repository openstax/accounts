FactoryGirl.define do
  factory :contact_info do
    user
    value                 { "#{SecureRandom.hex(4)}" }
    is_searchable         true
    public_value nil
  end
end
