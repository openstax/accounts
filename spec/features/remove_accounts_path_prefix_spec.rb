require 'rails_helper'

class DummyApp
  def call(env)
  end
end

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

  context "Request through /accounts should only be re routed when applicable" do
    it "shouldn\'t replace /accounts" do
      app_object = DummyApp.new
      expect(app_object).to receive(:call).with({'PATH_INFO' => '/blah/accounts', 'REQUEST_METHOD'=>'GET'})
      RemoveAccountsPathPrefix.new(app_object).call({'PATH_INFO' => '/blah/accounts', 'REQUEST_METHOD'=>'GET'})
    end

    it "should replace /accounts" do
      app_object = DummyApp.new
      expect(app_object).to receive(:call).with({'PATH_INFO' => '/blah', 'REQUEST_METHOD'=>'GET'})
      RemoveAccountsPathPrefix.new(app_object).call({'PATH_INFO' => '/accounts/blah', 'REQUEST_METHOD'=>'GET'})
    end

    it "should replace /accounts once given twice" do
      app_object = DummyApp.new
      expect(app_object).to receive(:call).with({'PATH_INFO' => '/blah/accounts', 'REQUEST_METHOD'=>'GET'})
      RemoveAccountsPathPrefix.new(app_object).call({'PATH_INFO' => '/accounts/blah/accounts', 'REQUEST_METHOD'=>'GET'})
    end

    it "should render image" do
      app_object = DummyApp.new
      expect(app_object).to receive(:call).with({'PATH_INFO' => '/assets/bg-login.jpg', 'REQUEST_METHOD'=>'GET'})
      RemoveAccountsPathPrefix.new(app_object).call({'PATH_INFO' => '/accounts/assets/bg-login.jpg', 'REQUEST_METHOD'=>'GET'})
      #expect(page).to have_content("img[src*='/assets/bg-login.jpg']")
    end

    it "should render js" do
      app_object = DummyApp.new
      expect(app_object).to receive(:call).with({'PATH_INFO' => '/assets/admin.js', 'REQUEST_METHOD'=>'GET'})
      RemoveAccountsPathPrefix.new(app_object).call({'PATH_INFO' => '/accounts/assets/admin.js', 'REQUEST_METHOD'=>'GET'})
      #expect(page).to have_content("(function( global, factory )")
    end
  end
end