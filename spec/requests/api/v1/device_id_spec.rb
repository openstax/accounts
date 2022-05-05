require 'rails_helper'

RSpec.describe 'device ID tracking',
               type: :request, api: true, version: :v1 do

  let!(:user) do
    create_user 'user@example.com'
  end

  let!(:user_token) do
    FactoryBot.create :doorkeeper_access_token,
                       application: FactoryBot.create(:doorkeeper_application),
                       resource_owner_id: user.id
  end

  context "logged in" do
    it "sets the device ID cookie" do
      api_get "/api/user", user_token
      expect(response.cookies["oxdid"]).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    end

    it "does not change" do
      original = cookies["oxdid"] = SecureRandom.uuid
      api_get "/api/user"
      expect(response.cookies["oxdid"]).to eq nil # because it isn't being changed (set)
    end

    it "gets fixed if messed up" do
      cookies["oxdid"] = "foo"
      api_get "/api/user", user_token
      expect(response.cookies["oxdid"]).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    end
  end
end
