FactoryGirl.define do
  factory :message_body do
    html '<p>Hello There!</p>'
    text 'Hello There!'
    short_text 'Hello!'

    after(:build) do |message_body, evaluator|
      message_body.message ||= FactoryGirl.build(:message, body: message_body)
    end
  end
end
