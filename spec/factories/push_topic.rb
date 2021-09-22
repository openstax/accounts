FactoryBot.define do
  factory :push_topic do
    topic_name { 'ContactChange' }
    topic_salesforce_id { "0IF4C0#{SecureRandom.alphanumeric(9)}" }
  end
end
