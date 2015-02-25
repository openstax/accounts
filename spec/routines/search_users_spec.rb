require 'spec_helper'

describe SearchUsers do

  let!(:user_1)          { FactoryGirl.create :user_with_emails,
                                              first_name: 'John',
                                              last_name: 'Stravinsky',
                                              username: 'jstrav' }
  let!(:user_2)          { FactoryGirl.create :user,
                                              first_name: 'Mary',
                                              last_name: 'Mighty',
                                              full_name: 'Mary Mighty',
                                              username: 'mary' }
  let!(:user_3)          { FactoryGirl.create :user,
                                              first_name: 'Johnathon',
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
    MarkContactInfoVerified.call(user_1.contact_infos.email_addresses.first)
    MarkContactInfoVerified.call(user_4.contact_infos.email_addresses.first)
    user_4.contact_infos.email_addresses.first.update_attribute(:value, 'jstoly292929@hotmail.com')
  end

  context "When performing a query" do
    let(:query_options){ {} }

    subject { SearchUsers.call(query, query_options).outputs.items.to_a }

    context "by username" do
      let(:query){ 'username:jst' }
      context "using exact matching" do
        let(:query_options){ { exact: true } }
        it { should be_empty }
      end

      context "when not specifying any options" do
        it { should eq [user_3, user_1] }
      end

      context "with an exact match" do
        let(:query){ 'username:jstrav' }
        it { should eq [user_1] }
      end
    end

    context "should ignore leading wildcards on searches" do
      let(:query){ 'username:%rav' }
      it { should be_empty }
    end

    context "should match based on one first name" do
      context "using exact matching" do
        context "with a non matching query" do
          let(:query){'first_name:"Jo"'}
          let(:query_options){ { exact: true } }
          it { should be_empty }
        end
        context "with matching query" do
          let(:query){'first_name:"John"'}
          let(:query_options){ { exact: true } }
          it { should eq [user_1] }
        end
      end
      let(:query){'first_name:"John"'}
      it { should eq [user_3, user_1] }
    end

    context "should match based on one full name" do
      let(:query){ 'full_name:"Mary Mighty"' }
      it { should eq [user_2] }
    end

    context "should match based on an exact email address" do
      let(:query){ "email:#{user_1.contact_infos.email_addresses.first.value}" }
      it { should eq [user_1] }
    end

    context "should not match based on an incomplete email address" do
      let(:query){
        email = user_1.contact_infos.email_addresses.first.value.split('@').first
        "email:#{email}"
      }
      it { should be_empty }
    end

    it "should not match unsearchable email addresses" do
      ea = user_1.contact_infos.email_addresses.first
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
