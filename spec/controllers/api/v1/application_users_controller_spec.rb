require 'rails_helper'

describe Api::V1::ApplicationUsersController, type: :controller, api: true, version: :v1 do

  let!(:untrusted_application)     { FactoryGirl.create :doorkeeper_application }
  let!(:trusted_application)     { FactoryGirl.create :doorkeeper_application, :trusted }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_2)          { FactoryGirl.create :user_with_emails,
                                              first_name: 'Bob',
                                              last_name: 'Michaels' }

  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
    application: untrusted_application,
    resource_owner_id: user_2.id }

  let!(:untrusted_application_token) { FactoryGirl.create :doorkeeper_access_token,
    application: untrusted_application,
    resource_owner_id: nil }
  let!(:trusted_application_token) { FactoryGirl.create :doorkeeper_access_token,
    application: trusted_application,
    resource_owner_id: nil }

  let!(:billy_users) {
    (0..45).to_a.collect{|ii|
      user = FactoryGirl.create :user,
                                first_name: "Billy#{ii.to_s.rjust(2, '0')}",
                                last_name: "Fred_#{(45-ii).to_s.rjust(2,'0')}",
                                username: "billy_#{ii.to_s.rjust(2, '0')}"
      FactoryGirl.create :application_user, user: user,
                                            application: untrusted_application,
                                            unread_updates: 0
    }
  }

  let!(:bob_brown) { FactoryGirl.create :user, first_name: "Bob", last_name: "Brown", username: "foo_bb" }
  let!(:bob_jones) { FactoryGirl.create :user, first_name: "Bob", last_name: "Jones", username: "foo_bj" }
  let!(:tim_jones) { FactoryGirl.create :user, first_name: "Tim", last_name: "Jones", username: "foo_tj" }

  before(:each) do
    user_2.reload
    [bob_brown, bob_jones, tim_jones].each do |user|
      FactoryGirl.create :application_user, user: user,
                         application: untrusted_application,
                         unread_updates: 0
    end
  end

  describe "find by username" do
    it "returns a single result when username matches" do
      api_get :find_by_username, untrusted_application_token, parameters: { username: 'foo_bb' }
      expect(response.code).to eq('200')
      expected_response = {
        id: bob_brown.application_users.first.id,
        user: user_matcher(bob_brown, include_private_data: false),
        unread_updates: 0
      }
      expect(response.body_as_hash).to match(expected_response)
    end

    it "responds with http status not found when not found" do
      api_get :find_by_username, untrusted_application_token, parameters: { username: 'foo' }
      expect(response).to have_http_status :not_found
    end

    it "responds with http status forbidden when called by anonymous" do
      api_get :find_by_username, nil, parameters: { username: 'foo' }
      expect(response).to have_http_status :forbidden
    end

    it "only finds users belonging to the requesting application" do
      # bob_brown is not a member of the "trusted_application"
      expect( bob_brown.application_users.where( application_id: trusted_application.id ) ).to be_empty
      # therefore no results will be returned
      api_get :find_by_username, trusted_application_token, parameters: { username: bob_brown.username }
      expect(response).to have_http_status :not_found
    end
  end

  describe "index" do

    it "returns a single result well" do
      api_get :index, untrusted_application_token, parameters: {q: 'first_name:bob last_name:Michaels'}
      expect(response.code).to eq('200')

      expected_response = {
        total_count: 1,
        items: [ user_matcher(user_2, include_private_data: false) ]
      }

      expect(response.body_as_hash).to match(expected_response)
    end

    it "should return the 2nd page when requested" do
      api_get :index, untrusted_application_token, parameters: {q: 'username:billy', page: '1', per_page: '10'}
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["total_count"]).to eq 46
      expect(outcome["items"].length).to eq 10
      expect(outcome["items"][0]["username"]).to eq "billy_10"
      expect(outcome["items"][9]["username"]).to eq "billy_19"
    end

    it "should return the incomplete 5th page when requested" do
      api_get :index, untrusted_application_token, parameters: {q: 'username:billy', page: '4', per_page: '10'}
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["total_count"]).to eq 46
      expect(outcome["items"].length).to eq 6
      expect(outcome["items"][0]["username"]).to eq "billy_40"
      expect(outcome["items"][5]["username"]).to eq "billy_45"
    end

    it "should allow sort by multiple fields in different directions" do
      api_get :index, untrusted_application_token, parameters: {q: 'username:foo', order_by: "first_name, last_name DESC"}
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["items"].length).to eq 3
      expect(outcome["items"][0]["username"]).to eq "foo_bj"
      expect(outcome["items"][1]["username"]).to eq "foo_bb"
      expect(outcome["items"][2]["username"]).to eq "foo_tj"

      expect(outcome["items"].length).to eq 3
      expect(outcome["items"][0]["username"]).to eq "foo_bj"
      expect(outcome["items"][1]["username"]).to eq "foo_bb"
      expect(outcome["items"][2]["username"]).to eq "foo_tj"
    end

    it "should return no users if no one uses an app" do
      api_get :index, trusted_application_token, parameters: {q: 'first_name:bob last_name:Michaels'}
      expect(response.code).to eq('200')

      expected_response = {
        total_count: 0,
        items: []
      }.to_json

      expect(response.body).to eq(expected_response)
    end

    it "should return only users that use an app" do
      # Make one app user
      trusted_app_user = FactoryGirl.create :application_user,
                                            application: trusted_application,
                                            user: user_2

      api_get :index, trusted_application_token, parameters: {q: 'first_name:bob last_name:Michaels'}
      expect(response.code).to eq('200')

      expected_response = {
        total_count: 1,
        items: [ user_matcher(user_2, include_private_data: true) ]
      }

      expect(response.body_as_hash).to match(expected_response)
    end

  end

  describe "updates" do

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
      ApplicationUser.update_all('unread_updates = unread_updates + 1')
      api_get :updates, untrusted_application_token
      expect(response.body_as_hash.count).to eq 50
    end

    it "should let the calling app limit the number of users" do
      ApplicationUser.update_all('unread_updates = unread_updates + 1')
      api_get :updates, untrusted_application_token, parameters: {limit: 3}
      expect(response.body_as_hash.count).to eq 3
    end

  end

  describe "updated" do

    it "should not let an app mark another app's updates as read" do
      app_user = user_2.application_users.first

      expect(app_user.reload.unread_updates).to eq 1

      api_put :updated, trusted_application_token, raw_post_data: [
        {id: app_user.id, read_updates: 1}].to_json

      expect(app_user.reload.unread_updates).to eq 1
    end

  end

end
