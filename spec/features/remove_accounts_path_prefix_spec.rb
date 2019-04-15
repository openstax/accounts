require 'rails_helper'

describe "Remove accounts path prefix" do
  # Ensure that the config.ru gets loaded before these tests
  let(:app) {
    Rack::Builder.new do
      eval File.read(Rails.root.join('config.ru'))
    end
  }

  let(:request) { Rack::MockRequest.new(app) }

  context "Requests should get routed to the appropriate controllers" do
    it "should recieve profile info in show page" do
      expect_any_instance_of(Api::V1::UsersController).to receive(:show)
      request.get("/accounts/api/user")
    end

    it "should be home page" do
      expect_any_instance_of(StaticPagesController).to receive(:home)
      request.get("/accounts")
    end

    it "should be start to sign up" do
      expect_any_instance_of(SignupController).to receive(:start)
      request.get("/accounts/signup")
    end
  end

  context "redirects work" do
    it "should redirect home page to login page with prefix" do
      response = request.get("/accounts")
      expect(URI(response.location).path).to eq "/accounts/login"
    end
  end

end
