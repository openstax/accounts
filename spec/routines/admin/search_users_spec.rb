require 'rails_helper'

RSpec.describe Admin::SearchUsers, type: :routine do

  let!(:user_1)          do
    FactoryBot.create :user_with_emails, first_name: 'John',
                                          last_name: 'Stravinsky',
                                          username: 'jstrav'
  end
  let!(:user_2)          do
    FactoryBot.create :user, first_name: 'Mary',
                              last_name: 'Mighty',
                              username: 'mary'
  end
  let!(:user_3)          do
    FactoryBot.create :user, first_name: 'John',
                              last_name: 'Stead',
                              username: 'jstead'
  end
  let!(:user_4)          do
    FactoryBot.create :user_with_emails, first_name: 'Bob',
                                          last_name: 'JST',
                                          username: 'bigbear'
  end

  before(:each) do
    user_4.contact_infos.email_addresses.order(:value).first.update(
      value: 'jstoly292929@hotmail.com'
    )
  end

  it "should match based on one first name" do
    outcome = described_class.call('first_name:"John"').outputs.items.to_a
    expect(outcome).to eq [user_3, user_1]
  end

  it "should match based on name" do
    outcome = described_class.call('name:"Mary Mighty"').outputs.items.to_a
    expect(outcome).to eq [user_2]
  end

  it "should match based on one full name" do
    outcome = described_class.call('full_name:"Mary Mighty"').outputs.items.to_a
    expect(outcome).to eq [user_2]
  end

  it "should match on full uuid" do
    uuid = user_1.uuid
    outcome = described_class.call("uuid:#{uuid}").outputs.items.to_a
    expect(outcome).to eq [user_1]
  end

  it "should match on partial uuid" do
    partial_uuid = user_1.uuid.split('-')[0]
    outcome = described_class.call("uuid:#{partial_uuid}").outputs.items.to_a
    expect(outcome).to eq [user_1]
  end

  it "should match based on a partial email address" do
    email = user_1.contact_infos.email_addresses.order(:value).first.value.split('@').first
    outcome = described_class.call("email:#{email}").outputs.items.to_a
    expect(outcome).to eq [user_1]
  end

  it "should return all results if the query is empty" do
    outcome = described_class.call("").outputs.items.to_a
    [user_4, user_3, user_1, user_2].each do |user|
      expect(outcome).to include(user)
    end
  end

  it "should match any fields when no prefix given" do
    [ user_1, user_2, user_3, user_4 ].each_with_index do |user, index|
    end
    outcome = described_class.call("st").outputs.items.to_a
    expect(outcome).to eq [user_4, user_3, user_1]
  end

  it "should match any fields when no prefix given and intersect when prefix given" do
    [ user_1, user_2, user_3, user_4 ].each_with_index do |user, index|
    end
    outcome = described_class.call("John first_name:John").outputs.items.to_a
    expect(outcome).to eq [user_3, user_1]
  end

  it "shouldn't allow users to add their own wildcards" do
    outcome = described_class.call("first_name:'e%r'").outputs.items.to_a
    expect(outcome).to eq []
  end

  it "should gather space-separated unprefixed search terms" do
    [ user_1, user_2, user_3, user_4 ].each_with_index do |user, index|
    end
    outcome = described_class.call("john strav").outputs.items.to_a
    expect(outcome).to eq [user_1]
  end

  context "pagination and sorting" do

    let!(:billy_users) do
      (0..45).to_a.map do |ii|
        FactoryBot.create :user,
                           first_name: "Billy#{ii.to_s.rjust(2, '0')}",
                           last_name: "Bob_#{(45-ii).to_s.rjust(2,'0')}",
                           username: "billy_#{ii.to_s.rjust(2, '0')}"
      end
    end

    it "should return the first page of values by default in default order" do
      outcome = described_class.call("last_name:Bob").outputs.items.all
      expect(outcome.length).to eq 20
      expect(outcome[0]).to eq User.where(last_name: "Bob_00").first
      expect(outcome[19]).to eq User.where(last_name: "Bob_19").first
    end

    it "should return the 2nd page when requested" do
      outcome = described_class.call("last_name:Bob", page: 1).outputs.items.all
      expect(outcome.length).to eq 20
      expect(outcome[0]).to eq User.where(last_name: "Bob_20").first
      expect(outcome[19]).to eq User.where(last_name: "Bob_39").first
    end

    it "should return the incomplete 3rd page when requested" do
      outcome = described_class.call("last_name:Bob", page: 2).outputs.items.all
      expect(outcome.length).to eq 6
      expect(outcome[5]).to eq User.where(last_name: "Bob_45").first
    end

  end

  context "sorting" do

    let!(:bob_brown) do
      FactoryBot.create :user, first_name: "Bob", last_name: "Brown", username: "foo_bb"
    end
    let!(:bob_jones) do
      FactoryBot.create :user, first_name: "Bob", last_name: "Jones", username: "foo_bj"
    end
    let!(:tim_jones) do
      FactoryBot.create :user, first_name: "Tim", last_name: "Jones", username: "foo_tj"
    end

    it "should allow sort by multiple fields in different directions" do
      outcome = described_class.call(
        "last_name:jones", order_by: "first_name DESC"
      ).outputs.items.to_a
      expect(outcome).to eq [tim_jones, bob_jones]

      outcome = described_class.call(
        "last_name:jones", order_by: "first_name ASC"
      ).outputs.items.to_a
      expect(outcome).to eq [bob_jones, tim_jones]
    end

  end

end
