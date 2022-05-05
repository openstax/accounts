require 'rails_helper'

# Moved multiple request specs here from the controller spec

RSpec.describe 'Api::V1::ApplicationUsers multiple requests',
               type: :request, api: true, version: :v1 do

  let!(:untrusted_application) { FactoryBot.create :doorkeeper_application }
  let!(:trusted_application)   { FactoryBot.create :doorkeeper_application, :trusted }
  let!(:user_2)       do
    create_user 'user2@openstax.org'
  end

  let!(:user_2_token) do
    FactoryBot.create :doorkeeper_access_token,
                       application: untrusted_application,
                       resource_owner_id: user_2.id
  end

  let!(:untrusted_application_token) do
    FactoryBot.create :doorkeeper_access_token,
                       application: untrusted_application,
                       resource_owner_id: nil
  end
  let!(:trusted_application_token) do
    FactoryBot.create :doorkeeper_access_token,
                       application: trusted_application,
                       resource_owner_id: nil
  end

  let(:updated_endpoint) { "/api/application_users/updated" }
  let(:updates_endpoint) { "/api/application_users/updates" }

  context "updates" do
    let(:app_user) { user_2.application_users.first }
    let(:expected_response) do
      -> do
        [
          {
            id: app_user.id,
            user: user_matcher(user_2.reload, include_private_data: false),
            unread_updates: app_user.unread_updates
          }
        ]
      end
    end

    it "should return properly formatted JSON responses" do
      expect(app_user.unread_updates).to eq 1

      user_2.first_name = 'Bo'
      user_2.save!

      expect(app_user.reload.unread_updates).to eq 2

      api_get updates_endpoint, untrusted_application_token

      expect(response.body_as_hash).to match(expected_response.call)

      api_get updates_endpoint, untrusted_application_token

      expect(response.body_as_hash).to match(expected_response.call)

      user_2.first_name = 'Bob'
      user_2.save!
      user_2.reload

      expect(app_user.reload.unread_updates).to eq 3

      api_get updates_endpoint, untrusted_application_token

      expect(response.body_as_hash).to match(expected_response.call)

      app_user.unread_updates = 2
      app_user.save!

      api_get updates_endpoint, untrusted_application_token

      expect(response.body_as_hash).to match(expected_response.call)

      app_user.unread_updates = 0
      app_user.save!

      api_get updates_endpoint, untrusted_application_token

      expect(response.body_as_hash).to match([])
    end

  end

  context "updated" do
    let(:app_user) { user_2.application_users.first }

    it "should properly change unread_updates" do
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

      api_put(updated_endpoint,
        untrusted_application_token,
        params: [
          {user_id: user_2.id, read_updates: 1}
        ].to_json
      )

      expect(response.status).to eq(204)

      expect(app_user.reload.unread_updates).to eq 4

      api_put(updated_endpoint,
        untrusted_application_token,
        params: [
          {user_id: user_2.id, read_updates: 1}
        ].to_json
      )

      expect(response.status).to eq(204)

      expect(app_user.reload.unread_updates).to eq 4

      api_put(updated_endpoint, untrusted_application_token,
        params: [
          {user_id: user_2.id, read_updates: 4}
        ].to_json
      )
      expect(response.status).to eq(204)

      expect(app_user.reload.unread_updates).to eq 0
    end

    it "should not let a user call it through an app" do
      api_get updates_endpoint, user_2_token
      #byebug
      expect(response).to have_http_status :forbidden
      api_put updated_endpoint, user_2_token
      expect(response).to have_http_status :forbidden
    end

  end

end
