require 'rails_helper'

module Oauth

  describe ApplicationsController, type: :controller do

    let!(:admin) { FactoryBot.create :user, :terms_agreed, :admin }
    let!(:user)  { FactoryBot.create :user, :terms_agreed }
    let!(:user2) { FactoryBot.create :user }

    let!(:trusted_application_admin)   { FactoryBot.create :doorkeeper_application, :trusted }
    let!(:untrusted_application_admin) { FactoryBot.create :doorkeeper_application }
    let!(:trusted_application_user)    { FactoryBot.create :doorkeeper_application, :trusted }
    let!(:untrusted_application_user)  { FactoryBot.create :doorkeeper_application }
    let!(:trusted_application_user2)   { FactoryBot.create :doorkeeper_application, :trusted }
    let!(:untrusted_application_user2) { FactoryBot.create :doorkeeper_application }

    before(:each) do
      trusted_application_admin.owner.add_member(admin)
      untrusted_application_admin.owner.add_member(admin)
      trusted_application_user.owner.add_member(user)
      untrusted_application_user.owner.add_member(user)
      trusted_application_user2.owner.add_member(user2)
      untrusted_application_user2.owner.add_member(user2)
    end

    it "should redirect users that haven't signed contracts" do
      load 'db/seeds.rb'

      FinePrint::Contract.second.destroy
      expect(FinePrint::Contract.count).to eq 1

      controller.sign_in! user2
      get(:index)
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :applications).to be_nil

      get :show, id: untrusted_application_user2.id
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil

      get(:new)
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil

      post :create, doorkeeper_application: {
        name: 'Some app',
        redirect_uri: 'https://www.example.com',
        trusted: true
      }
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil

      get :edit, id: untrusted_application_user2.id
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil

      put :update, id: untrusted_application_user2.id, application: {
        name: 'Some other name',
        redirect_uri: 'https://www.example.net',
        trusted: true
      }
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil

      delete :destroy, id: untrusted_application_user2.id
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil
    end

    it "should not let a user get the list of his applications" do
      controller.sign_in! user
      get(:index)
      expect(response).to have_http_status :forbidden
    end

    it "should let an admin get the list of all applications" do
      controller.sign_in! admin
      get(:index)
      expect(response).to have_http_status :success
      expect(assigns :applications).to include(untrusted_application_user)
      expect(assigns :applications).to include(trusted_application_user)
      expect(assigns :applications).to include(untrusted_application_user2)
      expect(assigns :applications).to include(trusted_application_user2)
      expect(assigns :applications).to include(untrusted_application_admin)
      expect(assigns :applications).to include(trusted_application_admin)
    end

    it "should not let a user get his own application" do
      controller.sign_in! user
      get :show, id: untrusted_application_user.id
      expect(response).to have_http_status :forbidden
    end

    it "should not let a user get someone else's application" do
      controller.sign_in! user
      get :show, id: untrusted_application_admin.id
      expect(response).to have_http_status :forbidden
    end

    it "should let an admin get someone else's application" do
      controller.sign_in! admin
      get :show, id: untrusted_application_user.id
      expect(response).to have_http_status :success
      expect(assigns(:application).name).to eq(untrusted_application_user.name)
      expect(assigns(:application).redirect_uri).to eq(untrusted_application_user.redirect_uri)
      expect(assigns(:application).trusted).to eq(untrusted_application_user.trusted)
    end

    it "should not let a user get new" do
      controller.sign_in! user
      get(:new)
      expect(response).to have_http_status :forbidden
    end

    it "should let an admin get new" do
      controller.sign_in! admin
      get(:new)
      expect(response).to have_http_status :success
    end

    it "should not let a user create an application" do
      controller.sign_in! user
      post :create, doorkeeper_application: {
        name: 'Some app',
        redirect_uri: 'https://www.example.com',
        trusted: true
      }
      expect(response).to have_http_status :forbidden
    end

    it "should let an admin create an application" do
      controller.sign_in! admin
      post :create, doorkeeper_application: {
        name: 'Some app',
        redirect_uri: 'https://www.example.com',
        trusted: true
      }
      id = assigns(:application).id
      expect(id).not_to be_nil
      expect(response).to redirect_to(oauth_application_path(id))
      expect(assigns(:application).name).to eq('Some app')
      expect(assigns(:application).redirect_uri).to eq('https://www.example.com')
      expect(assigns(:application).trusted).to eq(true)
    end

    it "should not let a user edit his own application" do
      controller.sign_in! user
      get :edit, id: untrusted_application_user.id
      expect(response).to have_http_status :forbidden
    end

    it "should not let a user edit someone else's application" do
      controller.sign_in! user
      get :edit, id: untrusted_application_admin.id
      expect(response).to have_http_status :forbidden
    end

    it "should let an admin edit someone else's application" do
      controller.sign_in! admin
      get :edit, id: untrusted_application_user.id
      expect(response).to have_http_status :success
      expect(assigns(:application).name).to eq(untrusted_application_user.name)
      expect(assigns(:application).redirect_uri).to eq(untrusted_application_user.redirect_uri)
      expect(assigns(:application).trusted).to eq(untrusted_application_user.trusted)
    end

    it "should not let a user update his own untrusted application" do
      controller.sign_in! user

      put :update, id: untrusted_application_user.id,
                   doorkeeper_application: {
                     name: 'Some other name',
                     redirect_uri: 'https://www.example.net',
                     trusted: true
                   }

      expect(response).to have_http_status :forbidden
    end

    it "should not let a user update someone else's application" do
      controller.sign_in! user
      put :update, id: untrusted_application_admin.id,
                   doorkeeper_application: {
                     name: 'Some other name',
                     redirect_uri: 'https://www.example.net',
                     trusted: true
                   }
      expect(response).to have_http_status :forbidden
    end

    it "should let an admin update someone else's application" do
      controller.sign_in! admin
      put :update, id: untrusted_application_user.id,
                   doorkeeper_application: {
                     name: 'Some other name',
                     redirect_uri: 'https://www.example.net',
                     trusted: true
                   }
      expect(response).to redirect_to(oauth_application_path(untrusted_application_user.id))
      expect(assigns(:application).name).to eq('Some other name')
      expect(assigns(:application).redirect_uri).to eq('https://www.example.net')
      expect(assigns(:application).trusted).to eq(true)
    end

    it "should not let a user destroy an application" do
      controller.sign_in! user
      delete :destroy, id: untrusted_application_user.id
      expect(response).to have_http_status :forbidden
    end

    it "should let an admin destroy an application" do
      controller.sign_in! admin
      delete :destroy, id: untrusted_application_user.id
      expect(response).to redirect_to(oauth_applications_path)
      expect(assigns(:application).destroyed?).to eq(true)
    end

  end

end
