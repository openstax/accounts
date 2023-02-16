FactoryBot.define do
  factory :external_id do
    user
    external_id { SecureRandom.uuid }
  end
end
