require 'spec_helper'

describe MessageBody do

  let!(:message_body) { FactoryGirl.build(:message_body) }

  context 'validation' do

    it 'must have a valid message' do
      message_body.message = nil
      expect(message_body).not_to be_valid
      expect(message_body.errors.messages[:message]).to eq(["can't be blank"])
    end

    it 'must not be blank' do
      message_body.html = ''
      message_body.text = ''
      message_body.short_text = ''
      expect(message_body).not_to be_valid
      expect(message_body.errors.messages[:base]).to eq(["can't be blank"])
    end

    it 'must have a unique message' do
      message_body.save!
      message_body2 = FactoryGirl.build(:message_body,
                        message: message_body.message)
      expect(message_body2).not_to be_valid
      expect(message_body2.errors.messages[:message_id]).to eq(["has already been taken"])
    end

    it 'validates if it has a unique message and is not blank' do
      expect(message_body).to be_valid
    end

  end

end
