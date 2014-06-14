require "spec_helper"

module Oauth

  describe ApplicationsController do

    let!(:admin) { FactoryGirl.create :user, :terms_agreed, :admin }
    let!(:user) { FactoryGirl.create :user, :terms_agreed }
    let!(:user2) { FactoryGirl.create :user }

    let!(:trusted_application_admin) { FactoryGirl.create :doorkeeper_application, :trusted }
    let!(:untrusted_application_admin) { FactoryGirl.create :doorkeeper_application }
    let!(:trusted_application_user) { FactoryGirl.create :doorkeeper_application, :trusted }
    let!(:untrusted_application_user) { FactoryGirl.create :doorkeeper_application }
    let!(:trusted_application_user2) { FactoryGirl.create :doorkeeper_application, :trusted }
    let!(:untrusted_application_user2) { FactoryGirl.create :doorkeeper_application }

    before(:each) do
      trusted_application_admin.owner.add_user(admin)
      untrusted_application_admin.owner.add_user(admin)
      trusted_application_user.owner.add_user(user)
      untrusted_application_user.owner.add_user(user)
      trusted_application_user2.owner.add_user(user2)
      untrusted_application_user2.owner.add_user(user2)
    end

    it "should redirect users that haven't signed contracts" do
      controller.sign_in user2
      get :index
      expect(response.code).to eq('302')
      expect(assigns :applications).to be_nil

      get :show, id: untrusted_application_user2.id
      expect(response.code).to eq('302')
      expect(assigns :application).to be_nil

      get :new
      expect(response.code).to eq('302')
      expect(assigns :application).to be_nil

      post :create, :application => {name: 'Some app',
                                     redirect_uri: 'http://www.example.com',
                                     trusted: true}
      expect(response.code).to eq('302')
      expect(assigns :application).to be_nil

      get :edit, id: untrusted_application_user2.id
      expect(response.code).to eq('302')
      expect(assigns :application).to be_nil

      post :update, id: untrusted_application_user2.id, application: {name: 'Some other name', redirect_uri: 'http://www.example.net', trusted: true}
      expect(response.code).to eq('302')
      expect(assigns :application).to be_nil

      delete :destroy, id: untrusted_application_user2.id
      expect(response.code).to eq('302')
      expect(assigns :application).to be_nil
    end

    it "should let a user get the list of his applications" do
      controller.sign_in user
      get :index
      expect(response.code).to eq('200')
      expect(assigns :applications).to include(untrusted_application_user)
      expect(assigns :applications).to include(trusted_application_user)
      expect(assigns :applications).not_to include(untrusted_application_user2)
      expect(assigns :applications).not_to include(trusted_application_user2)
      expect(assigns :applications).not_to include(untrusted_application_admin)
      expect(assigns :applications).not_to include(trusted_application_admin)
    end

    it "should let an admin get the list of all applications" do
      controller.sign_in admin
      get :index
      expect(response.code).to eq('200')
      expect(assigns :applications).to include(untrusted_application_user)
      expect(assigns :applications).to include(trusted_application_user)
      expect(assigns :applications).to include(untrusted_application_user2)
      expect(assigns :applications).to include(trusted_application_user2)
      expect(assigns :applications).to include(untrusted_application_admin)
      expect(assigns :applications).to include(trusted_application_admin)
    end

    it "should let a user get his own application" do
      controller.sign_in user
      get :show, id: untrusted_application_user.id
      expect(response.code).to eq('200')
      expect(assigns(:application).name).to eq(untrusted_application_user.name)
      expect(assigns(:application).redirect_uri).to eq(untrusted_application_user.redirect_uri)
      expect(assigns(:application).trusted).to eq(untrusted_application_user.trusted)
    end

    it "should not let a user get someone else's application" do
      controller.sign_in user
      expect{get :show, id: untrusted_application_admin.id}.to raise_error(SecurityTransgression)
    end

    it "should let an admin get someone else's application" do
      controller.sign_in admin
      get :show, id: untrusted_application_user.id
      expect(response.code).to eq('200')
      expect(assigns(:application).name).to eq(untrusted_application_user.name)
      expect(assigns(:application).redirect_uri).to eq(untrusted_application_user.redirect_uri)
      expect(assigns(:application).trusted).to eq(untrusted_application_user.trusted)
    end

    it "should let a user get new" do
      controller.sign_in user
      get :new
      expect(response.code).to eq('200')
    end

    it "should let a user create an untrusted application" do
      controller.sign_in user
      post :create, :application => {name: 'Some app',
                                     redirect_uri: 'http://www.example.com',
                                     trusted: true}
      expect(response.code).to eq('302')
      expect(assigns(:application).name).to eq('Some app')
      expect(assigns(:application).redirect_uri).to eq('http://www.example.com')
      expect(assigns(:application).trusted).to eq(false)
    end

    it "should let an admin create a trusted application" do
      controller.sign_in admin
      post :create, :application => {name: 'Some app',
                                     redirect_uri: 'http://www.example.com',
                                     trusted: true}
      expect(response.code).to eq('302')
      expect(assigns(:application).name).to eq('Some app')
      expect(assigns(:application).redirect_uri).to eq('http://www.example.com')
      expect(assigns(:application).trusted).to eq(true)
    end

    it "should let an admin create a trusted application" do
      controller.sign_in admin
      post :create, :application => {name: 'Some app',
                                     redirect_uri: 'http://www.example.com',
                                     trusted: true}
      expect(response.code).to eq('302')
      expect(assigns(:application).name).to eq('Some app')
      expect(assigns(:application).redirect_uri).to eq('http://www.example.com')
      expect(assigns(:application).trusted).to eq(true)
    end

    it "should let a user edit his own application" do
      controller.sign_in user
      get :edit, id: untrusted_application_user.id
      expect(response.code).to eq('200')
      expect(assigns(:application).name).to eq(untrusted_application_user.name)
      expect(assigns(:application).redirect_uri).to eq(untrusted_application_user.redirect_uri)
      expect(assigns(:application).trusted).to eq(untrusted_application_user.trusted)
    end

    it "should not let a user edit someone else's application" do
      controller.sign_in user
      expect{get :edit, id: untrusted_application_admin.id}.to raise_error(SecurityTransgression)
    end

    it "should let an admin edit someone else's application" do
      controller.sign_in admin
      get :edit, id: untrusted_application_user.id
      expect(response.code).to eq('200')
      expect(assigns(:application).name).to eq(untrusted_application_user.name)
      expect(assigns(:application).redirect_uri).to eq(untrusted_application_user.redirect_uri)
      expect(assigns(:application).trusted).to eq(untrusted_application_user.trusted)
    end

    it "should let a user update his own untrusted application" do
      controller.sign_in user
      post :update, id: untrusted_application_user.id, application: {name: 'Some other name', redirect_uri: 'http://www.example.net', trusted: true}
      expect(response.code).to eq('302')
      expect(assigns(:application).name).to eq('Some other name')
      expect(assigns(:application).redirect_uri).to eq('http://www.example.net')
      expect(assigns(:application).trusted).to eq(false)
    end

    it "should not let a user update someone else's application" do
      controller.sign_in user
      expect{post :update, id: untrusted_application_admin.id, application: {name: 'Some other name', redirect_uri: 'http://www.example.net', trusted: true}}.to raise_error(SecurityTransgression)
    end

    it "should let an admin update someone else's application" do
      controller.sign_in admin
      post :update, id: untrusted_application_user.id, application: {name: 'Some other name', redirect_uri: 'http://www.example.net', trusted: true}
      expect(response.code).to eq('302')
      expect(assigns(:application).name).to eq('Some other name')
      expect(assigns(:application).redirect_uri).to eq('http://www.example.net')
      expect(assigns(:application).trusted).to eq(true)
    end

    it "should let a user destroy his own application" do
      controller.sign_in user
      delete :destroy, id: untrusted_application_user.id
      expect(response.code).to eq('302')
      expect(assigns(:application).destroyed?).to eq(true)
    end

    it "should not let a user destroy someone else's application" do
      controller.sign_in user
      expect{delete :destroy, id: untrusted_application_admin.id}.to raise_error(SecurityTransgression)
    end

    it "should let an admin destroy someone else's application" do
      controller.sign_in admin
      delete :destroy, id: untrusted_application_user.id
      expect(response.code).to eq('302')
      expect(assigns(:application).destroyed?).to eq(true)
    end

  end

end
