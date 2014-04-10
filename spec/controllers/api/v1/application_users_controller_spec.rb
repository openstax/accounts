require "spec_helper"

describe Api::V1::ApplicationUsersController, :type => :api, :version => :v1 do

  let!(:app_user) { FactoryGirl.create :application_user }
  let!(:untrusted_application)     { app_user.application }
  let!(:trusted_application)     { FactoryGirl.create :doorkeeper_application, :trusted }
  let!(:user_1)          { app_user.user }
  let!(:user_2)          { FactoryGirl.create :user_with_emails,
                                              first_name: 'Bob',
                                              last_name: 'Michaels' }
  
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
    application: untrusted_application,
    resource_owner_id: user_1.id }
  
  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
    application: untrusted_application,
    resource_owner_id: user_2.id }
  
  let!(:untrusted_application_token) { FactoryGirl.create :doorkeeper_access_token,
    application: untrusted_application,
    resource_owner_id: nil }
  let!(:trusted_application_token) { FactoryGirl.create :doorkeeper_access_token,
    application: trusted_application,
    resource_owner_id: nil }

  describe "create" do
    it "should let an app create an application_user for a user" do
      expect {
        api_post :create, user_2_token
      }.to change{user_2.application_users(true).count}.from(0).to(1)
      expect(response.code).to eq('201')
    end
    
    it "should not let an app create an application_user by itself" do
      expect {
        api_post :create, untrusted_application_token
      }.not_to change{untrusted_application.application_users(true).count}
      expect(response.code).to eq('403')
    end
  end

  describe "show" do
    it "should let an app get its application_user" do
      api_get :show, untrusted_application_token, parameters: { id: app_user.id }
      expect(response.code).to eq('200')
      expect(response.body).to eq({id: app_user.id, application_id: untrusted_application.id, user_id: app_user.user_id}.to_json)
    end

    it "should let a user get his application_user" do
      api_get :show, user_1_token, parameters: { id: app_user.id }
      expect(response.code).to eq('200')
      expect(response.body).to eq({id: app_user.id, application_id: app_user.application_id, user_id: user_1.id}.to_json)
    end
    
    it "should not let an app get another app's application_user" do
      api_get :show, trusted_application_token, parameters: { id: app_user.id }
      expect(response.code).to eq('403')
    end

    it "should not let a user get another user's application_user" do
      api_get :show, user_2_token, parameters: { id: app_user.id }
      expect(response.code).to eq('403')
    end
  end

  describe "update" do
    it "should let an app update its own application_user" do
      info = FactoryGirl.create :contact_info, user: user_1

      api_put :update, untrusted_application_token,
              raw_post_data: {default_contact_info_id: info.id},
              parameters: {id: app_user.id}
      expect(response.code).to eq('204')
      app_user.reload
      expect(app_user.default_contact_info).to eq info
    end

    it "should let a user update his application_user" do
      info = FactoryGirl.create :contact_info, user: user_1

      api_put :update, user_1_token,
              raw_post_data: {default_contact_info_id: info.id},
              parameters: {id: app_user.id}
      expect(response.code).to eq('204')
      app_user.reload
      expect(app_user.default_contact_info).to eq info
    end

    it "should not let an app update another app's application_user" do
      info = FactoryGirl.create :contact_info, user: user_1

      api_put :update, trusted_application_token,
              raw_post_data: {default_contact_info_id: info.id},
              parameters: {id: app_user.id}
      expect(response.code).to eq('403')
      app_user.reload
      expect(app_user.default_contact_info).not_to eq info
    end

    it "should not let a user update another user's application_user" do
      info = FactoryGirl.create :contact_info, user: user_1
      
      api_put :update, user_2_token,
              raw_post_data: {default_contact_info_id: info.id},
              parameters: {id: app_user.id}
      expect(response.code).to eq('403')
      app_user.reload
      expect(app_user.default_contact_info).not_to eq info
    end
  end

  describe "destroy" do
    it "should let an app delete its application_user" do
      expect {
        api_delete :destroy, untrusted_application_token,
                   parameters: { id: app_user.id }
      }.to change{untrusted_application.application_users(true).count}.from(1).to(0)
      
      expect(response.code).to eq('204')
    end

    it "should let a user delete his application_user" do
      expect {
        api_delete :destroy, user_1_token,
        parameters: { id: app_user.id }
      }.to change{user_1.application_users(true).count}.from(1).to(0)
      
      expect(response.code).to eq('204')
    end

    it "should not let an app delete another app's application_user" do
      expect {
        api_delete :destroy, trusted_application_token,
        parameters: { id: app_user.id }
      }.not_to change{untrusted_application.application_users(true).count}
      
      expect(response.code).to eq('403')
    end

    it "should not let a user delete another user's application_user" do
      expect {
        api_delete :destroy, user_2_token,
        parameters: { id: app_user.id }
      }.not_to change{user_1.application_users(true).count}
      
      expect(response.code).to eq('403')
    end
  end

end