require 'spec_helper'

describe UsersWithEmails do
  
  let!(:user1) { FactoryGirl.create(:user_with_emails, emails_count: 2) }
  let!(:user2) { FactoryGirl.create(:user_with_emails, emails_count: 2) }

  it "finds one user when there is one match" do
    users = UsersWithEmails.all([user1.contact_infos.first.value])
    expect(users.first).to eq user1
  end

  it "finds two user when there are two matches" do
    users = UsersWithEmails.all([user1, user2].collect{|u| u.contact_infos.first.value})
    expect(users).to include user1
    expect(users).to include user2
  end

  it "finds nothing when there isn't a match" do
    users = UsersWithEmails.all(['no@match.com'])
    expect(users).to eq []
  end
  
end