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
