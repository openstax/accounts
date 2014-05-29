require 'spec_helper'

describe SendMessage do

  let!(:message) {
    FactoryGirl.build(:message)
  }

  it 'sends the message' do
    Mail::TestMailer.deliveries.clear

    expect{SendMessage.call(message).not_to raise_error}

    expect(Mail::TestMailer.deliveries).to be_empty
  end

end
