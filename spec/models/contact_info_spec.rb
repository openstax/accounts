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
    let(:user1){ FactoryBot.create :user }
    let(:user2){ FactoryBot.create :user }

    let!(:email1) { FactoryBot.build(:email_address, user: user1,
                                      verified: true, value: 'my1@email.com') }
    let!(:email2) { FactoryBot.build(:email_address, user: user2,
                                      verified: true, value: 'my2@email.com') }

    it 'does not allow the same user to have a repeated email address regardless of verification and case' do
      email1.save!
      expect(email2).to be_valid
      email2.user = email1.user
      email2.value = email1.value.upcase
      expect(email2).not_to be_valid
      expect(email2).to have_error(:value, :taken)
      email2.verified = false
      expect(email2).not_to be_valid
      expect(email2).to have_error(:value, :taken)
    end

    it 'does not allow two users to have the same verified email with different case' do
      email1.save!
      email2.value = email1.value.upcase
      expect(email2).not_to be_valid
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
      expect(email2).to have_error(:user, :last_verified)
    end

    context 'when altering email value' do
      before(:each){
        email1.save
        email2.save
      }

      it 'does allow a user to add an already used verified email but not to verify it' do
        email1.verified = true
        email1.save
        newemail = user2.email_addresses.build value: email1.value
        expect(newemail.save).to be true
        newemail.verified = true
        expect(newemail.save).to be false
        expect(newemail).to have_error(:value, :already_confirmed)
      end

      it 'does allow a user to add an already used unverified email and to verify it' do
        email1.verified = false
        email1.save
        newemail = user2.email_addresses.build value: email1.value
        expect(newemail.save).to be true
        newemail.verified = true
        expect(newemail.save).to be true
        expect(newemail.errors).to be_empty
      end

      it 'does not allow a user to update their email to be a duplicate of a verified email' do
        email1.save!
        email2.save!
        email1.value = email2.value
        expect(email1.save).to be false
        expect(email1).to have_error(:value, :already_confirmed)
      end

      it 'does allow a user to update their email to be a dupe of an unverified email' do
        email1.save!
        email2.verified = false
        email2.save!
        email1.value = email2.value
        expect(email1.save).to be true
        expect(email1.errors).to be_empty
      end
    end
  end

end
