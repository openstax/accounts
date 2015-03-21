require 'spec_helper'

describe Message do

  let!(:message) { FactoryGirl.build(:message, recipients_count: 0) }
  let!(:user_1)  { message.user }

  (2..7).each do |n|
    let!("user_#{n}".to_sym) { FactoryGirl.create :user_with_emails }
  end

  before(:each) do
    message.message_recipients << MessageRecipient.new(message: message,
      contact_info: user_2.contact_infos.first, recipient_type: :to)
    message.message_recipients << MessageRecipient.new(
      message: message, user: user_3,
      contact_info: user_3.contact_infos.first, recipient_type: :to)

    message.message_recipients << MessageRecipient.new(message: message,
      contact_info: user_4.contact_infos.first, recipient_type: :cc)
    message.message_recipients << MessageRecipient.new(
      message: message, user: user_5,
      contact_info: user_5.contact_infos.first, recipient_type: :cc)

    message.message_recipients << MessageRecipient.new(message: message,
      contact_info: user_6.contact_infos.first, recipient_type: :bcc)
    message.message_recipients << MessageRecipient.new(
      message: message, user: user_7,
      contact_info: user_7.contact_infos.first, recipient_type: :bcc)
  end

  context 'validation' do

    it 'must have a valid body' do
      message.body = nil
      expect(message).not_to be_valid
      expect(message.errors.messages[:body]).to eq(["can't be blank"])
    end

    it 'must have a valid application' do
      message.application = nil
      expect(message).not_to be_valid
      expect(message.errors.messages[:application]).to eq(["can't be blank"])
    end

    it 'must have message_recipients' do
      message.message_recipients = []
      expect(message).not_to be_valid
      expect(message.errors.messages[:message_recipients]).to(
        eq(["can't be blank"]))
    end

    it 'must have a valid subject' do
      message.subject = ''
      expect(message).not_to be_valid
      expect(message.errors.messages[:subject]).to eq(["can't be blank"])
    end

    it 'must have a valid subject_prefix' do
      message.subject_prefix = ''
      expect(message).not_to be_valid
      expect(message.errors.messages[:subject_prefix]).to eq(["can't be blank"])
    end

    it 'validates if it has all the required fields' do
      expect(message).to be_valid
    end

  end

  context 'addresses' do

    it "returns the from, to, cc and bcc addresses" do
      message.save!
      message.reload

      expect(message.from_address).to(
        eq(message.application.email_from_address))

      [user_2, user_3].each do |user|
        expect(message.to_addresses).to include(user.contact_infos.first.value)
      end

      [user_4, user_5].each do |user|
        expect(message.cc_addresses).to include(user.contact_infos.first.value)
      end

      [user_6, user_7].each do |user|
        expect(message.bcc_addresses).to include(user.contact_infos.first.value)
      end
    end

    it "returns the to, cc and bcc arrays" do
      message.save!
      message.reload

      expect(message.to).to(
        eq({'literals' => [user_2.contact_infos.first.value],
            'user_ids' => [user_3.id]}))

      expect(message.cc).to(
        eq({'literals' => [user_4.contact_infos.first.value],
            'user_ids' => [user_5.id]}))

      expect(message.bcc).to(
        eq({'literals' => [user_6.contact_infos.first.value],
            'user_ids' => [user_7.id]}))
    end

  end

end
