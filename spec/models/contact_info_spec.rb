require 'spec_helper'

describe ContactInfo do

  context 'validation' do
    it 'does not accept empty value' do
      info = ContactInfo.create
      expect(info).not_to be_valid
      expect(info.errors.messages[:value]).to eq(["can't be blank"])
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
