require 'rails_helper'

RSpec.describe ExternalUserCredentialsController, type: :routing do
  it "routes to #new" do
    expect(get('/external_user_credentials/new')).to route_to('external_user_credentials#new')
  end

  it "routes to #create" do
    expect(post('/external_user_credentials')).to route_to('external_user_credentials#create')
  end
end
