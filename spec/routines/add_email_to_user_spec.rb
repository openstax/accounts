require 'rails_helper'

describe AddEmailToUser do
  let(:user) { FactoryGirl.create :user }

  context 'when email address is valid' do
    it 'adds it to the user' do
      expect(EmailAddress.find_by_value('user@example.com')).to be_nil

      AddEmailToUser.call('user@example.com', user, already_verified: true)

      email = EmailAddress.find_by_value('user@example.com')
      expect(email).not_to be_nil
      expect(email.user).to eq(user)
      expect(email.verified).to eq true
      expect(email.confirmation_code).to be_nil

      expect(EmailAddress.find_by_value('user2@example.com')).to be_nil

      AddEmailToUser.call('user2@example.com', user)

      email = EmailAddress.find_by_value('user2@example.com')
      expect(email).not_to be_nil
      expect(email.user).to eq(user)
      expect(email.verified).to eq false
      expect(email.confirmation_code).not_to be_nil
    end

    it 'can verify an existing unverified email' do
      AddEmailToUser.call('user@example.com', user, already_verified: false)
      expect(user.email_addresses.first.verified).to eq false
      AddEmailToUser.call('user@example.com', user, already_verified: true)
      expect(user.email_addresses.first.verified).to eq true
    end

    it 'does not die when email already exists' do
      AddEmailToUser.call('user@example.com', user, already_verified: true)
      result = AddEmailToUser.call('user@example.com', user, already_verified: true)
      expect(result.errors.none?).to eq true
    end

    it 'defaults to :auto_verify_emails secret setting if :already_verified not specified' do
      AddEmailToUser.call('user@example.com', user)
      expect(user.email_addresses.first.verified).to eq false

      begin
        Rails.application.secrets[:auto_verify_emails] = true

        AddEmailToUser.call('user@example.com', user)
        expect(user.email_addresses.first.verified).to eq true
      ensure
        Rails.application.secrets.delete :auto_verify_emails
      end
    end
  end

  context 'when email address is not valid' do
    it 'does not add it to the user' do
      expect(EmailAddress.find_by_value('example.com')).to be_nil

      AddEmailToUser.call('example.com', user)

      expect(EmailAddress.find_by_value('example.com')).to be_nil
    end
  end

end
