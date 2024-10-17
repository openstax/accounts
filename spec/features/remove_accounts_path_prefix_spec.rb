require 'rails_helper'

describe "Remove accounts path prefix" do
  let(:app) { Rails.application }
  let(:request) { Rack::MockRequest.new(app) }

  context "Requests should get routed to the appropriate controllers" do
    it "should receive profile info in show page" do
      expect_any_instance_of(Api::V1::UsersController).to receive(:show)
      request.get("/accounts/api/user")
    end

    it "should be home page" do
      expect_any_instance_of(StaticPagesController).to receive(:home)
      request.get("/accounts")
    end

    it "should be welcome to newflow sign up" do
      expect_any_instance_of(Newflow::SignupController).to receive(:welcome)
      response = request.get("/accounts/signup")
      expect(response.get_header('Location')).to end_with('/accounts/i/signup')
      request.get("/accounts/i/signup")
    end
  end

  context "redirects work" do
    it "should redirect home page to login page with prefix" do
      response = request.get("/accounts")
      expect(URI(response.location).path).to eq "/accounts/i/login"
    end
  end

end
