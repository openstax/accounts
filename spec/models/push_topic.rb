require 'rails_helper'

RSpec.describe PushTopic, type: :model do
  subject(:push_topic) { FactoryBot.create :push_topic }

  it 'can be created' do
    expect(push_topic.topic_name).to eq('ContactChange')
    expect(push_topic.topic_salesforce_id).to start_with('0IF4C0')
  end
end
