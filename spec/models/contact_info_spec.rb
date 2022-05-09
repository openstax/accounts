require 'rails_helper'

RSpec.describe ContactInfo, type: :model do
  subject(:contact_info) { FactoryBot.create :email_address }

  it { is_expected.to validate_presence_of(:value) }
  it { is_expected.to validate_uniqueness_of(:value).scoped_to(:type).case_insensitive }

  context 'validation' do
    it 'strips values before validation' do
      info = ContactInfo.new(type: 'EmailAddress', value: ' bob@example.com ')
      info.valid?
      expect(info.value).to eq 'bob@example.com'
    end

    it 'does not accept empty value or type' do
      info = ContactInfo.new
      expect(info).not_to be_valid
      expect(info).to have_error(:value, :blank)
      expect(info).to have_error(:type, :blank)
    end

    it 'does not accept invalid types' do
      expect{ContactInfo.new(type: 'User')}.to raise_error(ActiveRecord::SubclassNotFound)
    end

    it 'defaults to not searchable' do
      info = ContactInfo.new(type: 'EmailAddress', value: 'my@email.com')
      expect(info.is_searchable).to eq false
    end
  end

  context 'verified user emails' do
    let(:user1) { FactoryBot.create :user }
    let(:user2) { FactoryBot.create :user }

    let!(:email1) do
      FactoryBot.build :email_address, user: user1, verified: true, value: 'my1@example.com'
    end
    let!(:email2) do
      FactoryBot.build :email_address, user: user2, verified: true, value: 'my2@example.com'
    end

    it 'does not allow removing the last verified email address' do
      email2.value = 'email2@example.com'
      email2.user = email1.user
      email2.save!
      email1.save!
      email1.destroy
      expect(email1.destroyed?).to eq true
      email2.destroy
      expect(email2.destroyed?).to eq false
      expect(email2).to have_error(:user, :last_verified)
    end

    context 'when altering email value' do
      before(:each) do
        email1.save
        email2.save
      end

      it 'does not allow a user to add an already used email' do
        email1.verified = false
        email1.save
        newemail = user2.email_addresses.build value: email1.value
        expect(newemail.valid?).to eq false
        expect(newemail).to have_error(:value, :taken)
      end

      it 'does not allow a user to update their email to be a duplicate of another email' do
        email1.save!
        email2.verified = false
        email2.save!
        email1.value = email2.value
        expect(email1.valid?).to eq false
        expect(email1).to have_error(:value, :taken)
      end
    end
  end
end
