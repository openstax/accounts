require 'spec_helper'

describe EmailAddress do
  context 'validates email address' do
    it 'returns no error for valid email addresses' do
      email = FactoryGirl.create :email_address
      email.value = 'user@example.com'
      expect(email).to be_valid

      email.value = 'first.last@my.mail.com'
      expect(email).to be_valid
    end

    it 'returns errors for email address without @' do
      email = FactoryGirl.create :email_address
      email.value = 'example.com'
      expect(email).not_to be_valid
    end

    it 'returns errors for email address that starts with @' do
      email = FactoryGirl.create :email_address
      email.value = '@example.com'
      expect(email).not_to be_valid
    end

    it 'returns errors for email address that ends with @' do
      email = FactoryGirl.create :email_address
      email.value = 'user@'
      expect(email).not_to be_valid
    end

    it 'returns errors for email address that has more than one @' do
      email = FactoryGirl.create :email_address
      email.value = 'user@example.com@example.com'
      expect(email).not_to be_valid
    end

    it 'returns errors for email address that does not have a valid domain name' do
      email = FactoryGirl.create :email_address
      email.value = 'user@localhost'
      expect(email).not_to be_valid
    end

  end
end
