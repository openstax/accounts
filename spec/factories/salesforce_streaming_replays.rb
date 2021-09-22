FactoryBot.define do
  factory :salesforce_streaming_replay do
    replay_id { SecureRandom.random_number(3) }
  end
end
