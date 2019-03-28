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
  let(:user) {
    create_user('user').tap do |user|
      verified_emails.each do |verified_email|
        create_email_address_for(user, verified_email)
      end

      unverified_emails.each do |unverified_email|
        create_email_address_for(user, unverified_email, SecureRandom.hex(32))
      end
    end
  }
  # test cached stuff
  before(:each) do
    #get login_path
    #signin_as(create_user('user'))
    mock_current_user(user)
    #log_in('user', 'password')
    #get '/profile'
  end

  context "Requests should get cached headers after a while" do
    it 'status code is 200' do
      get '/profile'
      assert_response 200
      expect(response.headers["Cache-Control"]).to eq("no-cache, no-store")

      #etag = response.headers["ETag"]
      #abort etag.inspect
      #request.env["HTTP_IF_NONE_MATCH"] = etag
    end

    it 'should not allow caching' do
      get '/api/user'
      expect(response.headers["Cache-Control"]).to eq("no-cache")
    end

    it 'should not cache assets' do
      get '/assets/bg-login.jpg'
      #assert_response 304
      expect(response.headers["Cache-Control"]).to eq("no-cache")
    end
  end
end