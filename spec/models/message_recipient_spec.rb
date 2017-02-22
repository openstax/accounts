require 'rails_helper'

describe MessageRecipient do

  let!(:message_recipient) { FactoryGirl.build(:message_recipient) }

  context 'validation' do

    it 'must have a valid message' do
      message_recipient.message = nil
      expect(message_recipient).not_to be_valid
      expect(message_recipient).to have_error(:message, :blank)
    end

    it 'must have a unique user' do
      message_recipient.save!
      message_recipient2 = FactoryGirl.build(:message_recipient,
        user: message_recipient.user, message: message_recipient.message)
      expect(message_recipient2).not_to be_valid
      expect(message_recipient2).to have_error(:user_id, :taken)
    end

    it 'must have a unique contact_info' do
      message_recipient.save!
      message_recipient2 = FactoryGirl.build(:message_recipient,
        contact_info: message_recipient.contact_info,
        message: message_recipient.message)
      expect(message_recipient2).not_to be_valid
      expect(message_recipient2).to have_error(:contact_info_id, :taken)
    end

    it 'validates if it has a message and unique contact_info and user' do
      expect(message_recipient).to be_valid
    end

  end

  context 'value' do

    it "returns the contact_info's value or nil" do
      expect(message_recipient.value).to(
        eq(message_recipient.contact_info.value))

      message_recipient.contact_info = nil

      expect(message_recipient.value).to be_nil
    end

  end

end
