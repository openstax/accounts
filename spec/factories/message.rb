FactoryBot.define do
  factory :message do
    association :application, factory: :doorkeeper_application
    user
    send_externally_now false
    subject 'Hello World!'
    subject_prefix '[Testing]'

    transient do
      recipients_count 1
    end

    after(:build) do |message, evaluator|
      message.body ||= FactoryBot.build(:message_body, message: message)
      evaluator.recipients_count.times do
        message.message_recipients << FactoryBot.build(:message_recipient,
                                                        message: message)
      end
    end
  end
end
