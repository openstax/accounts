require 'rails_helper'

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

  let!(:user_4)          { FactoryGirl.create :user_with_emails,
                                              first_name: 'Bob',
                                              last_name: 'JST',
                                              username: 'bigbear' }

  let!(:billy_users) {
    (0..8).to_a.collect{|ii|
      FactoryGirl.create :user,
                         first_name: "Billy#{ii.to_s.rjust(2, '0')}",
                         last_name: "Bob_#{(45-ii).to_s.rjust(2,'0')}",
                         username: "billy_#{ii.to_s.rjust(2, '0')}"
    }
  }

  before(:each) do
    MarkContactInfoVerified.call(user_1.contact_infos.email_addresses.order(:value).first)
    MarkContactInfoVerified.call(user_4.contact_infos.email_addresses.order(:value).first)
    user_4.contact_infos.email_addresses.order(:value).first.update_attribute(:value, 'jstoly292929@hotmail.com')
    user_1.reload
  end

  it "should match based on username" do
    outcome = SearchUsers.call('username:jstra').outputs.items.to_a
    expect(outcome).to eq [user_1]
  end

  it "should ignore leading wildcards on username searches" do
    outcome = SearchUsers.call('username:%rav').outputs.items.to_a
    expect(outcome).to eq []
  end

  it "should match based on one first name" do
    outcome = SearchUsers.call('first_name:"John"').outputs.items.to_a
    expect(outcome).to eq [user_3, user_1]
  end

  it "should match based on one full name" do
    outcome = SearchUsers.call('name:"Mary Mighty"').outputs.items.to_a
    expect(outcome).to eq [user_2]
  end

  it "should match based on an exact email address" do
    email = user_1.contact_infos.email_addresses.order(:value).first.value
    outcome = SearchUsers.call("email:#{email}").outputs.items.to_a
    expect(outcome).to eq [user_1]
  end

  it "should not match based on an incomplete email address" do
    email = user_1.contact_infos.email_addresses.order(:value).first.value.split('@').first
    outcome = SearchUsers.call("email:#{email}").outputs.items.to_a
    expect(outcome).to eq []
  end

  it "should not match unsearchable email addresses" do
    ea = user_1.contact_infos.email_addresses.order(:value).first
    email = ea.value
    ea.is_searchable = false
    ea.save!
    outcome = SearchUsers.call("email:#{email}").outputs.items.to_a
    expect(outcome).to eq []

    ea.is_searchable = true
    ea.save!
    outcome = SearchUsers.call("email:#{email}").outputs.items.to_a
    expect(outcome).to eq [user_1]
  end

  it "should return no results if the limit is exceeded" do
    outcome = SearchUsers.call("").outputs.items.to_a
    expect(outcome).to be_empty
  end

  it "should match any fields when no prefix given" do
    outcome = SearchUsers.call("jst").outputs.items.to_a
    expect(outcome).to eq [user_4, user_3, user_1]
  end

  it "should match any fields when no prefix given and intersect when prefix given" do
    outcome = SearchUsers.call("jst username:jst").outputs.items.to_a
    expect(outcome).to eq [user_3, user_1]
  end

  it "shouldn't allow users to add their own wildcards" do
    outcome = SearchUsers.call("username:'%ar'").outputs.items.to_a
    expect(outcome).to eq []
  end

  it "should gather space-separated unprefixed search terms" do
    outcome = SearchUsers.call("john mighty").outputs.items.to_a
    expect(outcome).to eq [user_3, user_1, user_2]
  end

  context "sorting" do

    let!(:bob_brown) { FactoryGirl.create :user, first_name: "Bob", last_name: "Brown", username: "foo_bb" }
    let!(:bob_jones) { FactoryGirl.create :user, first_name: "Bob", last_name: "Jones", username: "foo_bj" }
    let!(:tim_jones) { FactoryGirl.create :user, first_name: "Tim", last_name: "Jones", username: "foo_tj" }

    it "should allow sort by multiple fields in different directions" do
      outcome = SearchUsers.call("username:foo", order_by: "first_name, last_name DESC").outputs.items.to_a
      expect(outcome).to eq [bob_jones, bob_brown, tim_jones]

      outcome = SearchUsers.call("username:foo", order_by: "first_name, last_name ASC").outputs.items.to_a
      expect(outcome).to eq [bob_brown, bob_jones, tim_jones]
    end

  end

end
