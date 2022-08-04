FactoryBot.define do
  factory :book do
    salesforce_id { "a0Z#{SecureRandom.alphanumeric(15)}" }
    salesforce_name { Faker::Book.title }
    official_name { Faker::Book.title }
  end
end
