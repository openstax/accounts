require 'rails_helper'

# Moved multiple request specs here from the controller spec

describe 'Api::V1::ApplicationUsers multiple requests', type: :request, api: true, version: :v1 do

  let!(:untrusted_application)     { FactoryGirl.create :doorkeeper_application }
  let!(:trusted_application)     { FactoryGirl.create :doorkeeper_application, :trusted }
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

  let(:updated_endpoint) { "/api/application_users/updated" }
  let(:updates_endpoint) { "/api/application_users/updates" }

  describe "updates" do

    it "should return properly formatted JSON responses" do
      app_user = user_2.application_users.first
      expect(app_user.unread_updates).to eq 1

      user_2.first_name = 'Bo'
      user_2.save!

      expect(app_user.reload.unread_updates).to eq 2

      api_get updates_endpoint, untrusted_application_token

      expected_response = [{
        id: app_user.id,
        user: user_matcher(user_2.reload, include_private_data: false),
        unread_updates: 2
      }]

      expect(response.body_as_hash).to match(expected_response)

      api_get updates_endpoint, untrusted_application_token

      expect(response.body_as_hash).to match(expected_response)

      user_2.first_name = 'Bob'
      user_2.save!
      user_2.reload

      expect(app_user.reload.unread_updates).to eq 3

      api_get updates_endpoint, untrusted_application_token

      expected_response = [{
        id: app_user.id,
        user: user_matcher(user_2.reload, include_private_data: false),
        unread_updates: 3
      }]

      expect(response.body_as_hash).to match(expected_response)

      app_user.unread_updates = 2
      app_user.save!

      api_get updates_endpoint, untrusted_application_token

      expected_response = [{
        id: app_user.id,
        user: user_matcher(user_2.reload, include_private_data: false),
        unread_updates: 2
      }]

      expect(response.body_as_hash).to match(expected_response)

      app_user.unread_updates = 0
      app_user.save!

      api_get updates_endpoint, untrusted_application_token
      expected_response = [].to_json

      expect(response.body).to eq(expected_response)
    end

  end

  describe "updated" do
    it "should properly change unread_updates" do
      app_user = user_2.application_users.first
      expect(app_user.unread_updates).to eq 1

      user_2.first_name = 'Bo'
      user_2.save!

      expect(app_user.reload.unread_updates).to eq 2

      user_2.first_name = 'Bob'
      user_2.save!

      expect(app_user.reload.unread_updates).to eq 3

      user_2.first_name = 'B'
      user_2.save!

      expect(app_user.reload.unread_updates).to eq 4

      api_put updated_endpoint, untrusted_application_token, raw_post_data: [
        {user_id: user_2.id, read_updates: 2}].to_json

      expect(response.status).to eq(204)

      expect(app_user.reload.unread_updates).to eq 4

      api_put updated_endpoint, untrusted_application_token, raw_post_data: [
        {user_id: user_2.id, read_updates: 1}].to_json

      expect(response.status).to eq(204)

      expect(app_user.reload.unread_updates).to eq 4

      api_put updated_endpoint, untrusted_application_token, raw_post_data: [
        {user_id: user_2.id, read_updates: 4}].to_json

      expect(response.status).to eq(204)

      expect(app_user.reload.unread_updates).to eq 0
    end

    it "should not let a user call it through an app" do
      api_get updates_endpoint, user_2_token
      expect(response).to have_http_status :forbidden
      api_put updated_endpoint, user_2_token
      expect(response).to have_http_status :forbidden
    end

  end

end
