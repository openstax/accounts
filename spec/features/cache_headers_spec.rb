require 'rails_helper'

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.around(:each, :caching) do |example|
    caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = example.metadata[:caching]
    example.run
    ActionController::Base.perform_caching = caching
  end
end

describe "Cache-Control headers", :type => :request do

  let(:verified_emails) { ["one@verified.com"] }
  let(:unverified_emails) { [] }
  let(:user) { create_user('user@example.com') }
  # test cached stuff
  before(:each) do
    mock_current_user(user)
  end

  context "Requests should get cached headers after a while" do
    it 'status code is 200' do
      get '/profile'
      assert_response 200
      expect(response.headers["Cache-Control"]).to eq("no-cache, no-store")
    end

    it 'should not allow caching' do
      get '/api/user'
      expect(response.headers["Cache-Control"]).to eq("no-cache")
    end

    it 'should not cache assets' do
      get '/assets/bg-login.jpg'
      expect(response.headers["Cache-Control"]).to match /public/
    end
  end
end
