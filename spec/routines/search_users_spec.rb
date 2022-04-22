require 'rails_helper'

RSpec.describe SearchUsers, type: :routine do

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

  let!(:billy_users) do
    (0..8).to_a.map do |ii|
      FactoryBot.create :user,
                         first_name: "Billy#{ii.to_s.rjust(2, '0')}",
                         last_name: "Bob_#{(45-ii).to_s.rjust(2,'0')}",
                         username: "billy_#{ii.to_s.rjust(2, '0')}"
    end
  end

  before(:each) do
    MarkContactInfoVerified.call(user_1.contact_infos.email_addresses.order(:value).first)
    MarkContactInfoVerified.call(user_4.contact_infos.email_addresses.order(:value).first)
    user_4.contact_infos.email_addresses.order(:value).first.update(
      value: 'jstoly292929@hotmail.com'
    )
    user_1.reload
  end

  it "returns empty results when given empty search strings" do
    wildcard_fields = [:username, :first_name, :last_name, :full_name, :name, :any]
    wildcard_fields.each do |field|
      outputs = described_class.call("#{field}:\"\"").outputs
      expect(outputs.items).to be_empty # Because more than 10 results are returned
      expect(outputs.total_count).to be > described_class::MAX_MATCHING_USERS
    end

    exact_fields = [:id, :email]
    exact_fields.each do |field|
      outputs = described_class.call("#{field}:\"\"").outputs
      expect(outputs.items).to be_empty
      expect(outputs.total_count).to eq 0
    end
  end

  it "should ignore leading wildcards on username searches" do
    outcome = described_class.call('username:%rav').outputs.items.to_a
    expect(outcome).to eq []
  end

  it "should match based on one first name" do
    outcome = described_class.call('first_name:"John"').outputs.items.to_a
    expect(outcome).to eq [user_3, user_1]
  end

  it "should match based on one full name" do
    outcome = described_class.call('name:"Mary Mighty"').outputs.items.to_a
    expect(outcome).to eq [user_2]
  end

  it "should match based on an exact email address" do
    email = user_1.contact_infos.email_addresses.order(:value).first.value
    outcome = described_class.call("email:#{email}").outputs.items.to_a
    expect(outcome).to eq [user_1]
  end

  it "should not match based on an incomplete email address" do
    email = user_1.contact_infos.email_addresses.order(:value).first.value.split('@').first
    outcome = described_class.call("email:#{email}").outputs.items.to_a
    expect(outcome).to eq []
  end

  it "should not match unsearchable email addresses" do
    ea = user_1.contact_infos.email_addresses.order(:value).first
    email = ea.value
    ea.is_searchable = false
    ea.save!
    outcome = described_class.call("email:#{email}").outputs.items.to_a
    expect(outcome).to eq []

    ea.is_searchable = true
    ea.save!
    outcome = described_class.call("email:#{email}").outputs.items.to_a
    expect(outcome).to eq [user_1]
  end

  it "should return no results if the limit is exceeded" do
    outcome = described_class.call("").outputs.items.to_a
    expect(outcome).to be_empty
  end

  it "should match any fields when no prefix given" do
    outcome = described_class.call("John").outputs.items.to_a
    expect(outcome).to eq [user_3, user_1]
  end

  it "should match any fields when no prefix given and intersect when prefix given" do
    outcome = described_class.call("John first_name:John").outputs.items.to_a
    expect(outcome).to eq [user_3, user_1]
  end

  it "shouldn't allow users to add their own wildcards" do
    outcome = described_class.call("first_name:'%ohn'").outputs.items.to_a
    expect(outcome).to eq []
  end

  it 'should match both first and last name for an unprefixed search for two words' do
    outcome = described_class.call('john stravinsky').outputs.items.to_a
    expect(outcome).to eq [user_1] # Not user_2 even though his first name is John
  end

  it 'should match by full_name' do
    outcome = described_class.call('full_name:"john stravinsky"').outputs.items.to_a
    expect(outcome).to eq [user_1] # Not user_2 even though his first name is John
  end

  it 'should match by UUID' do
    outcome = described_class.call("uuid:#{user_3.uuid}").outputs.items.to_a
    expect(outcome).to eq [user_3]
  end

  it 'should match by id' do
    outcome = described_class.call("id:#{user_3.id}").outputs.items.to_a
    expect(outcome).to eq [user_3]
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
