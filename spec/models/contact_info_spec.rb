require 'rails_helper'

describe ContactInfo do

  context 'validation' do
    it 'strips values before validation' do
      info = ContactInfo.new(type: 'EmailAddress', value: ' bob@example.com ')
      info.valid?
      expect(info.value).to eq 'bob@example.com'
    end

    it 'does not accept empty value or type' do
      info = ContactInfo.new
      expect(info).not_to be_valid
      expect(info.errors.messages[:value]).to eq(["can't be blank"])
      expect(info.errors.messages[:type]).to eq(
        ["can't be blank"])
    end

    it 'does not accept invalid types' do
      expect{ContactInfo.new(type: 'User')}.to raise_error(ActiveRecord::SubclassNotFound)
    end

    it 'defaults to not searchable' do
      info = ContactInfo.new(type: 'EmailAddress', value: 'my@email.com')
      expect(info.is_searchable).to eq false
    end
  end

  context 'user emails' do

    let!(:email1) { FactoryGirl.build(:email_address, verified: true,
                                      value: 'my@email.com') }
    let!(:email2) { FactoryGirl.build(:email_address, verified: true,
                                      value: 'my@email.com') }

    it 'does not allow the same user to have a repeated email address' do
      email1.save!
      expect(email2).to be_valid
      email2.user = email1.user
      expect(email2).not_to be_valid
      expect(email2.errors.types[:value]).to include(:taken)
    end

    it 'does not allow removing the last verified email address' do
      email2.value = 'email2@test.com'
      email2.user = email1.user
      email2.save!
      email1.save!
      email1.destroy
      expect(email1.destroyed?).to be true
      email2.destroy
      expect(email2.destroyed?).to be false
      expect(email2.errors[:user].to_s).to include('unable to delete')
    end

  end

end
