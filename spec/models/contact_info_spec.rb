require 'spec_helper'

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

    it 'defaults to not searchable and not public' do
      info = ContactInfo.new(type: 'EmailAddress', value: 'my@email.com')
      expect(info.is_searchable).to eq false
      expect(info.is_public).to eq false
      info.public_value = 'm...@email.com'
      expect(info.is_public).to eq true
    end

    it 'validates the public_value' do
      info = FactoryGirl.build(:contact_info, type: 'EmailAddress',
                                              value: 'my@email.com')
      expect(info).to be_valid

      info.public_value = 'my@email.com'
      expect(info).to be_valid

      info.public_value = '...@email.com'
      expect(info).to be_valid
      info.public_value = 'my@...'
      expect(info).to be_valid

      info.public_value = 'my...'
      expect(info).to be_valid
      info.public_value = '...com'
      expect(info).to be_valid
      info.public_value = '....com'
      expect(info).to be_valid

      info.public_value = 'my@...com'
      expect(info).to be_valid
      info.public_value = 'my@....com'
      expect(info).to be_valid
      info.public_value = 'my@email...'
      expect(info).to be_valid

      info.public_value = 'my...com'
      expect(info).to be_valid
      info.public_value = 'my....com'
      expect(info).to be_valid
      info.public_value = 'm...l.com'
      expect(info).to be_valid
      info.public_value = 'm...com'
      expect(info).to be_valid
      info.public_value = 'm....com'
      expect(info).to be_valid
      info.public_value = 'my@email...m'
      expect(info).to be_valid
      info.public_value = 'my@e...m'
      expect(info).to be_valid
      info.public_value = 'my@email...com'
      expect(info).to be_valid

      info.public_value = 'm...m'
      expect(info).to be_valid
      info.public_value = 'my...m'
      expect(info).to be_valid
      info.public_value = 'm...com'
      expect(info).to be_valid
      info.public_value = 'my...com'
      expect(info).to be_valid

      info.public_value = 'my@e...l.com'
      expect(info).to be_valid
      info.public_value = 'my@email.c...m'
      expect(info).to be_valid
      info.public_value = 'm...@email.com'
      expect(info).to be_valid
      info.public_value = '...y@email.com'
      expect(info).to be_valid

      info.public_value = '...'
      expect(info).not_to be_valid

      info.public_value = 'my...@email.com'
      expect(info).not_to be_valid
      info.public_value = 'my@...email.com'
      expect(info).not_to be_valid
      info.public_value = 'my@email....com'
      expect(info).not_to be_valid
      info.public_value = 'm...y@email.com'
      expect(info).not_to be_valid
      info.public_value = '...my@email.com'
      expect(info).not_to be_valid
      info.public_value = 'my@email.com...'
      expect(info).not_to be_valid

      info.public_value = 'm...@e...m'
      expect(info).not_to be_valid
      info.public_value = 'm...@e...l.c...m'
      expect(info).not_to be_valid
      info.public_value = 'm..@email.com'
      expect(info).not_to be_valid
      info.public_value = 'm.@email.com'
      expect(info).not_to be_valid
      info.public_value = 'm....@email.com'
      expect(info).not_to be_valid
      info.public_value = 'my@email....'
      expect(info).not_to be_valid
      info.public_value = 'my@email....m'
      expect(info).not_to be_valid
      info.public_value = 'm....m'
      expect(info).not_to be_valid

      info.public_value = 'y...@email.com'
      expect(info).not_to be_valid
      info.public_value = 'm...@example.net'
      expect(info).not_to be_valid
      info.public_value = 'y...@example.net'
      expect(info).not_to be_valid
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
    let!(:user1) { FactoryGirl.create(:user_with_emails, emails_count: 2) }
    let!(:user2) { FactoryGirl.create(:user_with_emails, emails_count: 2) }

    it "finds one user when there is one match" do
      users = EmailAddress.where(:value => user1.contact_infos.first.value)
                          .with_users.collect{|e| e.user}
      expect(users.first).to eq user1
    end

    it "finds two user when there are two matches" do
      users = EmailAddress.where(:value => [user1, user2].collect{
                                             |u| u.contact_infos.first.value})
                          .with_users.collect{|e| e.user}
      expect(users).to include user1
      expect(users).to include user2
    end

    it "finds nothing when there isn't a match" do
      users = EmailAddress.where(:value => ['no@match.com'])
                          .with_users.collect{|e| e.user}
      expect(users).to eq []
    end
  end

end
