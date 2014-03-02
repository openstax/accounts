require 'spec_helper'

describe SearchUsers do
  
  let!(:user_1)          { FactoryGirl.create :user_with_emails, 
                                              first_name: 'John',
                                              last_name: 'Stravinsky',
                                              username: 'jstrav' }
  let!(:user_2)          { FactoryGirl.create :user,
                                              first_name: 'Mary',
                                              last_name: 'Mighty',
                                              username: 'mary' }
  let!(:user_3)          { FactoryGirl.create :user, 
                                              first_name: 'John',
                                              last_name: 'Stead',
                                              username: 'jstead' }

  before(:each) do
    MarkContactInfoVerified.call(user_1.contact_infos.email_addresses.first)
  end

  it "should match based on username" do
    outcome = SearchUsers.call('username:jstra').outputs.users.all
    expect(outcome).to eq [user_1]
  end

  it "should ignore leading wildcards on username searches" do
    outcome = SearchUsers.call('username:%rav').outputs.users.all
    expect(outcome).to eq []
  end

  it "should match based on one first name" do
    outcome = SearchUsers.call('first_name:"John"').outputs.users.all
    expect(outcome).to eq [user_1, user_3]
  end

  it "should match based on an exact email address" do
    email = user_1.contact_infos.email_addresses.first.value
    outcome = SearchUsers.call("email:#{email}").outputs.users.all
    expect(outcome).to eq [user_1]
  end

  it "should not match based on an incomplete email address" do
    email = user_1.contact_infos.email_addresses.first.value.split('@').first
    outcome = SearchUsers.call("email:#{email}").outputs.users.all
    expect(outcome).to eq []
  end

  it "should not return any results if the query is empty" do
    outcome = SearchUsers.call("").outputs.users.all
    expect(outcome).to eq []
  end

  it "should not return any results if there is no usable part of the query" do
    outcome = SearchUsers.call("blah:foo").outputs.users.all
    expect(outcome).to eq []
  end

end