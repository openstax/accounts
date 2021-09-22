require 'rails_helper'

RSpec.describe SalesforceStreamingReplay, type: :model do
  subject(:streaming_replay) { FactoryBot.create :salesforce_streaming_replay }

  it 'can be created' do
    expect(streaming_replay.replay_id).to be >= 0
  end
end
