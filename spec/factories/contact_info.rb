FactoryBot.define do
  factory :contact_info do
    user
    value            { "#{SecureRandom.hex(4)}" }
    is_searchable    { true }
    type             { 'EmailAddress' }

    trait(:verified) { verified { true } }
  end
end
