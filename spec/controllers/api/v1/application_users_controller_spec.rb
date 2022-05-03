require 'rails_helper'

RSpec.describe Api::V1::ApplicationUsersController, type: :controller, api: true, version: :v1 do

  let!(:untrusted_application) { FactoryBot.create :doorkeeper_application }
  let!(:trusted_application)   { FactoryBot.create :doorkeeper_application, can_access_private_user_data: true }

  let!(:untrusted_application_token) do
    FactoryBot.create :doorkeeper_access_token, application: untrusted_application,
                                                 resource_owner_id: nil
  end
  let!(:trusted_application_token) do
    FactoryBot.create :doorkeeper_access_token, application: trusted_application,
                                                 resource_owner_id: nil
  end

  let!(:user_1)          { FactoryBot.create :user }
  let!(:user_2)          do
    FactoryBot.create :user_with_emails,
                       first_name: 'Bob', last_name: 'Michaels', salesforce_contact_id: "somesfid"
  end
  let!(:billy_users) do
    (0..45).to_a.map do |ii|
      user = create_user "openstax_#{ii.to_s.rjust(2, '0')}@example.org"
      FactoryBot.create :application_user, user: user,
                                            application: untrusted_application,
                                            unread_updates: 0
    end
  end
  let!(:bob_brown) do
    FactoryBot.create :user, first_name: "Bob", last_name: "Brown", username: "foo_bb"
  end
  let!(:bob_jones) do
    FactoryBot.create :user, first_name: "Bob", last_name: "Jones", username: "foo_bj"
  end
  let!(:tim_jones) do
    FactoryBot.create :user, first_name: "Tim", last_name: "Jones", username: "foo_tj"
  end

  let!(:user_2_token)    do
    FactoryBot.create :doorkeeper_access_token, application: untrusted_application,
                                                 resource_owner_id: user_2.id
  end

  before(:each) do
    user_2.reload
    [bob_brown, bob_jones, tim_jones].each do |user|
      FactoryBot.create :application_user, user: user,
                         application: untrusted_application,
                         unread_updates: 0
    end
  end

  context "index" do

    it "returns a single result well" do
      api_get :index, untrusted_application_token, params: {
        q: 'first_name:bob last_name:Michaels'
      }
      expect(response.code).to eq('200')

      expected_response = {
        total_count: 1,
        items: [ user_matcher(user_2, include_private_data: false) ]
      }

      expect(response.body_as_hash).to match(expected_response)
    end

    it "should return the 2nd page when requested" do
      api_get :index, untrusted_application_token, params: {
        q: 'last_name:fred', page: '1', per_page: '10'
      }
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["total_count"]).to eq 46
      expect(outcome["items"].length).to eq 10
      expect(outcome["items"][0]["last_name"]).to eq "Fred_10"
      expect(outcome["items"][9]["last_name"]).to eq "Fred_19"
    end

    it "should return the incomplete 5th page when requested" do
      api_get :index, untrusted_application_token, params: {
        q: 'last_name:fred', page: '4', per_page: '10'
      }
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["total_count"]).to eq 46
      expect(outcome["items"].length).to eq 6
      expect(outcome["items"][0]["last_name"]).to eq "Fred_40"
      expect(outcome["items"][5]["last_name"]).to eq "Fred_45"
    end

    it "should allow sort by multiple fields in different directions" do
      api_get :index, untrusted_application_token, params: {q: 'last_name:jones', order_by: "first_name DESC"}
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["items"].length).to eq 2
      expect(outcome["items"][0]["first_name"]).to eq "Tim"
      expect(outcome["items"][1]["first_name"]).to eq "Bob"
    end

    it "should return no users if no one uses an app" do
      api_get :index, trusted_application_token, params: {
        q: 'first_name:bob last_name:Michaels'
      }
      expect(response.code).to eq('200')

      expected_response = {
        total_count: 0,
        items: []
      }.to_json

      expect(response.body).to eq(expected_response)
    end

    it "should return only users that use an app" do
      # Make one app user
      trusted_app_user = FactoryBot.create :application_user,
                                            application: trusted_application,
                                            user: user_2

      api_get :index, trusted_application_token, params: {
        q: 'first_name:bob last_name:Michaels'
      }
      expect(response.code).to eq('200')

      expected_response = {
        total_count: 1,
        items: [ user_matcher(user_2, include_private_data: true) ]
      }

      expect(response.body_as_hash).to match(expected_response)
    end

  end

  context "updates" do

    it "should return no results for an app without updated users" do
      app_user = user_2.application_users.first
      app_user.unread_updates = 0
      app_user.save!

      api_get :updates, untrusted_application_token

      expected_response = [].to_json

      expect(response.body).to eq(expected_response)
    end

    it "should not let a user call it through an app" do
      api_get :updates, user_2_token
      expect(response).to have_http_status :forbidden
    end

    it "should return all updated users by default" do
      ApplicationUser.update_all('unread_updates = unread_updates + 1') # rubocop:disable Rails/SkipsModelValidations
      api_get :updates, untrusted_application_token
      expect(response.body_as_hash.count).to eq 50
    end

    it "should let the calling app limit the number of users" do
      ApplicationUser.update_all('unread_updates = unread_updates + 1') # rubocop:disable Rails/SkipsModelValidations
      api_get :updates, untrusted_application_token, params: {limit: 3}
      expect(response.body_as_hash.count).to eq 3
    end

  end

  context "updated" do

    it "should not let an app mark another app's updates as read" do
      app_user = user_2.application_users.first

      expect(app_user.reload.unread_updates).to eq 1

      api_put :updated, trusted_application_token, body: [
        {id: app_user.id, read_updates: 1}
      ].to_json

      expect(app_user.reload.unread_updates).to eq 1
    end

  end

end
