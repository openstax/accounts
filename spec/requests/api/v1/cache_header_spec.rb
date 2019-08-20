require 'rails_helper'

# Moved multiple request specs here from the controller spec

RSpec.describe 'API cache header verification',
               type: :request, api: true, version: :v1 do

  let!(:untrusted_application) { FactoryBot.create :doorkeeper_application }
  let!(:trusted_application)   { FactoryBot.create :doorkeeper_application, :trusted }
  let!(:user_2)       do
    FactoryBot.create :user_with_emails,
                       first_name: 'Bob',
                       last_name: 'Michaels'
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

  it "should have headers that prevent caching in AWS" do
    api_get "/api/user", user_2_token
    expect(response.headers["Cache-Control"].split(',').each(&:strip!)).to include("max-age=0", "private")
  end
end
