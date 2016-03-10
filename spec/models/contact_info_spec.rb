require 'rails_helper'

describe ContactInfo do

  context 'validation' do
    it 'does not accept empty value or type' do
      info = ContactInfo.new
      expect(info).not_to be_valid
      expect(info.errors.messages[:value]).to eq(["can't be blank"])
      expect(info.errors.messages[:type]).to eq(
        ["can't be blank", "is not included in the list"])
    end

    it 'does not accept invalid types' do
      info = ContactInfo.new(type: 'User')
      expect(info).not_to be_valid
      expect(info.errors.messages[:type]).to eq(
        ["is not included in the list"])
    end

    it 'defaults to not searchable' do
      info = ContactInfo.new(type: 'EmailAddress', value: 'my@email.com')
      expect(info.is_searchable).to eq false
    end
  end

  context 'to_subclass' do
    let!(:user) { FactoryGirl.create(:user) }

    it 'returns self as a subclass' do
      info = ContactInfo.new(type: 'EmailAddress', value: 'invalid')
      info.user = user
      expect(info).to be_valid
      ea = info.to_subclass
      expect(ea).to be_a EmailAddress
      expect(ea).not_to be_valid
      ea.value = "user@example.com"
      expect(ea).to be_valid
    end
  end

  context 'user emails' do

    let!(:email1) { FactoryGirl.build(:email_address,
                                      value: 'my@email.com') }
    let!(:email2) { FactoryGirl.build(:email_address,
                                      value: 'my@email.com') }

    it 'does not allow the same user to have a repeated email address' do
      email1.save!
      expect(email2).to be_valid

      email2.user = email1.user
      expect(email2).not_to be_valid
      expect(email2.errors.types[:value]).to include(:taken)
    end

  end

end
