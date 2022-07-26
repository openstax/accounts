require 'rails_helper'

module Oauth

  describe ApplicationsController, type: :controller do

    before(:all) { load 'db/seeds.rb' }

    let!(:admin) { FactoryBot.create :user, :terms_agreed, :admin }
    let!(:user)  { FactoryBot.create :user, :terms_agreed }
    let!(:user2) { FactoryBot.create :user }
    let!(:not_oauth_admin_user) { FactoryBot.create :user, :terms_agreed }

    let!(:trusted_application_admin)   { FactoryBot.create :doorkeeper_application, :trusted }
    let!(:untrusted_application_admin) { FactoryBot.create :doorkeeper_application }
    let!(:trusted_application_user)    { FactoryBot.create :doorkeeper_application, :trusted }
    let!(:untrusted_application_user)  { FactoryBot.create :doorkeeper_application }
    let!(:trusted_application_user2)   { FactoryBot.create :doorkeeper_application, :trusted }
    let!(:untrusted_application_user2) { FactoryBot.create :doorkeeper_application }

    it "should let an admin update someone else's application" do
      controller.sign_in! admin
      put(:update,
        params: {
          id: untrusted_application_user.id,
          doorkeeper_application: {
            name: 'Some other name',
            redirect_uri: 'https://www.example.net',
            can_access_private_user_data: true
          }
        }
      )
      expect(response).to redirect_to(oauth_application_path(untrusted_application_user.id))
      expect(assigns(:application).name).to eq('Some other name')
      expect(assigns(:application).redirect_uri).to eq('https://www.example.net')
      expect(assigns(:application).can_access_private_user_data).to eq(true)
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

    it "should let an admin get someone else's application" do
      controller.sign_in! admin
      get(:show, params: { id: untrusted_application_user.id })
      expect(response).to have_http_status :success
      expect(assigns(:application).name).to eq(untrusted_application_user.name)
      expect(assigns(:application).redirect_uri).to eq(untrusted_application_user.redirect_uri)
      expect(assigns(:application).can_access_private_user_data).to eq(untrusted_application_user.can_access_private_user_data)
    end

    it "should let an admin get new" do
      controller.sign_in! admin
      get(:new)
      expect(response).to have_http_status :success
    end

    it "should let an admin create an application" do
      controller.sign_in! admin
      post(:create,
        params: {
          doorkeeper_application: {
            name: 'Some app',
            redirect_uri: 'https://www.example.com',
            can_message_users: true
          }
        }
      )

      id = assigns(:application).id
      expect(id).not_to be_nil
      expect(response).to redirect_to(oauth_application_path(id))
      expect(assigns(:application).name).to eq('Some app')
      expect(assigns(:application).redirect_uri).to eq('https://www.example.com')
    end

    it "should let an admin edit someone else's application" do
      controller.sign_in! admin
      get(:edit, params: { id: untrusted_application_user.id })
      expect(response).to have_http_status :success
      expect(assigns(:application).name).to eq(untrusted_application_user.name)
      expect(assigns(:application).redirect_uri).to eq(untrusted_application_user.redirect_uri)
    end

    it "should let an admin destroy an application" do
      controller.sign_in! admin
      delete(:destroy, params: { id: untrusted_application_user.id })
      expect(response).to redirect_to(oauth_applications_path)
      expect(assigns(:application).destroyed?).to eq(true)
    end

    it "should redirect users that haven't signed contracts" do
      load 'db/seeds.rb'

      FinePrint::Contract.second.destroy
      expect(FinePrint::Contract.count).to eq 1

      controller.sign_in! user2
      get(:index)
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :applications).to be_nil

      get(:show, params: { id: untrusted_application_user2.id })
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil

      get(:new)
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil

      post(:create,
        params: {
          doorkeeper_application: {
            name: 'Some app',
            redirect_uri: 'https://www.example.com',
            can_skip_oauth_screen: true
          }
        }
      )
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil

      get(:edit, params: { id: untrusted_application_user2.id })
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil

      put(:update,
        params: {
          id: untrusted_application_user2.id,
          application: {
            name: 'Some other name',
            redirect_uri: 'https://www.example.net',
            can_skip_oauth_screen: true
          }
        }
      )
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil

      delete(:destroy, params: { id: untrusted_application_user2.id })
      expect(response).to redirect_to pose_terms_path(terms: FinePrint::Contract.pluck(:id))
      expect(assigns :application).to be_nil
    end

    it "should not let a user get the list of his applications" do
      controller.sign_in! not_oauth_admin_user
      get(:index)
      expect(response).to have_http_status :forbidden
    end

    it "should not let a user get someone else's application" do
      controller.sign_in! user
      get(:show, params: { id: untrusted_application_admin.id })
      expect(response).to have_http_status :forbidden
    end

    it "should not let a user get new" do
      controller.sign_in! user
      get(:new)
      expect(response).to have_http_status :forbidden
    end

    it "should not let a user create an application" do
      controller.sign_in! user
      post(:create,
        params: {
          doorkeeper_application: {
            name: 'Some app',
            redirect_uri: 'https://www.example.com'
          }
        }
      )
      expect(response).to have_http_status :forbidden
    end

    it "should not let a user edit someone else's application" do
      controller.sign_in! user
      get(:edit, params: { id: untrusted_application_admin.id })
      expect(response).to have_http_status :forbidden
    end

    it "should not let a user update someone else's application" do
      controller.sign_in! user
      put(:update,
        params: {
          id: untrusted_application_admin.id,
          doorkeeper_application: {
            name: 'Some other name',
            redirect_uri: 'https://www.example.net',
            can_access_private_user_data: true
          }
        }
      )
      expect(response).to have_http_status :forbidden
    end

    it "should not let a user destroy an application" do
      controller.sign_in! user
      delete(:destroy, params: { id: untrusted_application_user.id })
      expect(response).to have_http_status :forbidden
    end

    it "should let an admin create an application with Oauth Admins" do
      controller.sign_in! admin
      post(:create,
        params: {
            doorkeeper_application: {
              name: 'Some app',
              redirect_uri: 'https://www.example.com',
              can_message_users: true,
            },
            member_ids: user2.id
        }
      )

      id = assigns(:application).id
      expect(id).not_to be_nil
      expect(response).to redirect_to(oauth_application_path(id))
      expect(assigns(:application).name).to eq('Some app')
      expect(assigns(:application).redirect_uri).to eq('https://www.example.com')
    end

    it "should let an oauth admin edit an application" do
      controller.sign_in! admin
      get(:edit, params: { id: trusted_application_admin.id })

      expect(response).to have_http_status :success
      expect(assigns(:application).redirect_uri).to eq(trusted_application_admin.redirect_uri)
    end

    it "should let an oauth admin update an application" do
      controller.sign_in! admin
      put(:update,
        params: {
          id: trusted_application_admin.id,
          doorkeeper_application: {
            redirect_uri: 'https://www.example.org'
          }
        }
      )
      expect(response).to redirect_to(oauth_application_path(trusted_application_admin.id))
      expect(assigns(:application).redirect_uri).to eq('https://www.example.org')
    end

    it "should let an admin add Oauth Admins" do
      controller.sign_in! admin
      post(:update,
        params: {
          id: untrusted_application_user.id,
          doorkeeper_application: {
            name: 'Some app',
            redirect_uri: 'https://www.example.com',
            can_message_users: true,
          },
          member_ids: user2.id
        }
      )

      id = assigns(:application).id
      expect(id).not_to be_nil
      expect(response).to redirect_to(oauth_application_path(id))
      expect(assigns(:application).name).to eq('Some app')
      expect(assigns(:application).redirect_uri).to eq('https://www.example.com')
    end
  end
end
