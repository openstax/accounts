require 'rails_helper'

describe 'device ID tracking', type: :request, api: true, version: :v1 do
  let(:uuid_regex) { /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/ }
  let(:consent_cookie) { 'consentid:abc,consent:yes,action:yes,necessary:yes,functional:yes,analytics:yes,performance:no' }

  let!(:user) do
    FactoryBot.create :user_with_emails,
                       first_name: 'Bob',
                       last_name: 'Michaels'
  end

  let!(:user_token) do
    FactoryBot.create :doorkeeper_access_token,
                       application: FactoryBot.create(:doorkeeper_application),
                       resource_owner_id: user.id
  end

  def deleted_oxdid?
    Array(response.headers['Set-Cookie']).join("\n").match?(/^oxdid=;.*expires=Thu, 01 Jan 1970/i)
  end

  context "with analytics consent" do
    before { cookies['cookieyes-consent'] = consent_cookie }

    it "sets the device ID cookie" do
      api_get "/api/user"
      expect(response.cookies["oxdid"]).to match(uuid_regex)
    end

    it "expires the cookie after 13 months" do
      api_get "/api/user"
      header = Array(response.headers['Set-Cookie']).find { |c| c.start_with?('oxdid=') }
      expires = Time.httpdate(header[/expires=([^;]+)/i, 1])
      expect(expires).to be_within(1.day).of(13.months.from_now)
    end

    it "does not change a valid existing ID" do
      cookies["oxdid"] = SecureRandom.uuid
      api_get "/api/user"
      expect(response.cookies["oxdid"]).to eq nil # because it isn't being changed (set)
    end

    it "gets fixed if messed up" do
      cookies["oxdid"] = "foo"
      api_get "/api/user"
      expect(response.cookies["oxdid"]).to match(uuid_regex)
    end

    it "sets the cookie when logged in" do
      api_get "/api/user", user_token
      expect(response.cookies["oxdid"]).to match(uuid_regex)
    end
  end

  context "without analytics consent" do
    it "does not set the cookie when there is no consent cookie" do
      api_get "/api/user"
      expect(response.cookies["oxdid"]).to eq nil
    end

    it "deletes an existing cookie" do
      cookies["oxdid"] = SecureRandom.uuid
      api_get "/api/user"
      expect(deleted_oxdid?).to eq true
    end

    it "does not set the cookie when analytics is declined" do
      cookies['cookieyes-consent'] = 'consentid:abc,consent:yes,necessary:yes,analytics:no'
      api_get "/api/user"
      expect(response.cookies["oxdid"]).to eq nil
    end

    it "deletes an existing cookie when analytics is declined" do
      cookies['cookieyes-consent'] = 'consentid:abc,consent:yes,necessary:yes,analytics:no'
      cookies["oxdid"] = SecureRandom.uuid
      api_get "/api/user"
      expect(deleted_oxdid?).to eq true
    end

    it "treats a malformed consent cookie as no consent" do
      cookies['cookieyes-consent'] = 'xanalytics:yes,analytics:yesterday,not-analytics:yes'
      api_get "/api/user"
      expect(response.cookies["oxdid"]).to eq nil
    end

    it "does not set the cookie when logged in" do
      api_get "/api/user", user_token
      expect(response.cookies["oxdid"]).to eq nil
    end
  end
end
