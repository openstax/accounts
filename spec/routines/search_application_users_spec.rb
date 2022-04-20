require 'rails_helper'

RSpec.describe SearchApplicationUsers do
  let!(:application) { FactoryBot.create :doorkeeper_application }

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
    [user_1, user_2, user_3].each do |user|
      FactoryBot.create :application_user, application: application, user: user
    end
    MarkContactInfoVerified.call(user_1.contact_infos.email_addresses.order(:value).first)
    MarkContactInfoVerified.call(user_4.contact_infos.email_addresses.order(:value).first)
    user_4.contact_infos.email_addresses.order(:value).first.update_attributes(
      :value: 'jstoly292929@hotmail.com'
    )
    user_1.reload
  end

  it "should not return results if application is nil" do
    outcome = described_class.call(nil, 'last_name:Stravinsky').outputs.items
    expect(outcome).to eq nil
  end

  it "should match based on one first name" do
    outcome = described_class.call(application, 'first_name:"John"').outputs.items.to_a
    expect(outcome).to eq [user_3, user_1]
  end

  it "should match based on one full name" do
    outcome = described_class.call(application, 'name:"Mary Mighty"').outputs.items.to_a
    expect(outcome).to eq [user_2]
  end

  it "should match based on an exact email address" do
    email = user_1.contact_infos.email_addresses.order(:value).first.value
    outcome = described_class.call(application, "email:#{email}").outputs.items.to_a
    expect(outcome).to eq [user_1]
  end

  it "should not match based on an incomplete email address" do
    email = user_1.contact_infos.email_addresses.order(:value).first.value.split('@').first
    outcome = described_class.call(application, "email:#{email}").outputs.items.to_a
    expect(outcome).to eq []
  end

  it "should return all results if the query is empty" do
    outcome = described_class.call(application, "").outputs.items.to_a
    expect(outcome).to eq [user_2, user_3, user_1]
  end

  it "should match any fields when no prefix given" do
    outcome = described_class.call(application, "John").outputs.items.to_a
    expect(outcome).to eq [user_3, user_1]
  end

  it "should match any fields when no prefix given and intersect when prefix given" do
    outcome = described_class.call(application, "John first_name:John").outputs.items.to_a
    expect(outcome).to eq [user_3, user_1]
  end

  it "shouldn't allow users to add their own wildcards" do
    outcome = described_class.call(application, "first_name:'%ohn'").outputs.items.to_a
    expect(outcome).to eq []
  end

  it "should gather space-separated unprefixed search terms" do
    outcome = described_class.call(application, "john strav").outputs.items.to_a
    expect(outcome).to eq [user_1]
  end

  context "pagination and sorting" do

    let!(:billy_users) do
      (0..45).to_a.map do |ii|
        FactoryBot.create(
          :user, first_name: "Billy#{ii.to_s.rjust(2, '0')}",
                 last_name: "Bob_#{(45-ii).to_s.rjust(2,'0')}",
                 username: "billy_#{ii.to_s.rjust(2, '0')}"
        ).tap do |user|
          FactoryBot.create :application_user, application: application, user: user
        end
      end
    end

    it "should return the first page of values by default in default order" do
      outcome = described_class.call(application, "last_name:Bob").outputs.items.to_a
      expect(outcome.length).to eq 20
      expect(outcome[0]).to eq User.where(last_name: "Bob_00").first
      expect(outcome[19]).to eq User.where(last_name: "Bob_19").first
    end

    it "should return the 2nd page when requested" do
      outcome = described_class.call(application, "last_name:Bob", page: 1).outputs.items.to_a
      expect(outcome.length).to eq 20
      expect(outcome[0]).to eq User.where(last_name: "Bob_20").first
      expect(outcome[19]).to eq User.where(last_name: "Bob_39").first
    end

    it "should return the incomplete 3rd page when requested" do
      outcome = described_class.call(application, "last_name:Bob", page: 2).outputs.items.to_a
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

    before(:each) do
      [bob_brown, bob_jones, tim_jones].each do |user|
        FactoryBot.create :application_user, application: application, user: user
      end
    end

    it "should allow sort by multiple fields in different directions" do
      outcome = described_class.call(
        application, "last_name:jones", order_by: "first_name DESC"
      ).outputs.items.to_a
      expect(outcome).to eq [tim_jones, bob_jones]

      outcome = described_class.call(
        application, "last_name:jones", order_by: "first_name ASC"
      ).outputs.items.to_a
      expect(outcome).to eq [bob_jones, tim_jones]
    end

  end

end
