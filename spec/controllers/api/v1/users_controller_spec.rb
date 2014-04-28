require "spec_helper"

describe Api::V1::UsersController, :type => :api, :version => :v1 do

  let!(:untrusted_application)     { FactoryGirl.create :doorkeeper_application }
  let!(:trusted_application)     { FactoryGirl.create :doorkeeper_application, :trusted }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_2)          { FactoryGirl.create :user_with_emails, first_name: 'Bob', last_name: 'Michaels' }
  let!(:admin_user)      { FactoryGirl.create :user, :admin }

  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token, 
                                              application: untrusted_application, 
                                              resource_owner_id: user_1.id }

  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token, 
                                              application: untrusted_application, 
                                              resource_owner_id: user_2.id }


  let!(:admin_token)       { FactoryGirl.create :doorkeeper_access_token, 
                                                application: untrusted_application, 
                                                resource_owner_id: admin_user.id }

  let!(:untrusted_application_token) { FactoryGirl.create :doorkeeper_access_token, 
                                                application: untrusted_application, 
                                                resource_owner_id: nil }

  let!(:trusted_application_token) { FactoryGirl.create :doorkeeper_access_token, 
                                                application: trusted_application, 
                                                resource_owner_id: nil }

  describe "show" do

    it "should let User get his own User" do
      api_get :show, user_1_token, parameters: {id: user_1.id}
      expect(response.code).to eq('200')
    end

    it "should not let User get another User" do
      api_get :show, user_1_token, parameters: {id: user_2.id}
      expect(response.code).to eq('403')
    end

    it "should let an admin get another User" do
      api_get :show, admin_token, parameters: {id: user_2.id}
      expect(response.code).to eq('200')
    end

    it "should let a trusted application get a User" do
      api_get :show, trusted_application_token, parameters: {id: admin_user.id}
      expect(response.code).to eq('200')
    end

    it "should not let an untrusted application get a User" do
      api_get :show, untrusted_application_token, parameters: {id: user_1.id}
      expect(response.code).to eq('403')
    end

    it "should return a properly formatted JSON response for low-info user" do
      api_get :show, user_1_token, parameters: {id: user_1.id}
      
      expected_response = {
        id: user_1.id,
        username: user_1.username,
        contact_infos: []
      }.to_json

      expect(response.body).to eq(expected_response)
    end

    it "should return a properly formatted JSON response for user with name and contact infos" do
      api_get :show, user_2_token, parameters: {id: user_2.id}
      
      expected_response = {
        id: user_2.id,
        username: user_2.username,
        first_name: user_2.first_name,
        last_name: user_2.last_name,
        contact_infos: user_2.contact_infos.collect{|ci| {id: ci.id, type: ci.type, value: ci.value, verified: ci.verified}}
      }.to_json

      expect(response.body).to eq(expected_response)
    end

  end

  describe "me" do

    it "should return a properly formatted JSON response for low-info user" do
      api_get :me, user_1_token, parameters: {id: user_1.id}
      
      expected_response = {
        id: user_1.id,
        username: user_1.username,
        contact_infos: []
      }.to_json

      expect(response.body).to eq(expected_response)
    end

    it "should not let a trusted application call me" do
      api_get :me, trusted_application_token, parameters: {id: user_1.id}
      expect(response.status).to eq(403)
    end

  end

  describe "update" do
    it "should let User update his own User" do
      api_put :update, user_2_token, raw_post_data: {first_name: "Jerry", last_name: "Mouse"}, 
                                     parameters: {id: user_2.id}
      expect(response.code).to eq('204')
      user_2.reload
      expect(user_2.first_name).to eq 'Jerry'
      expect(user_2.last_name).to eq 'Mouse'
    end

    it "should not let a user update another user" do
      api_put :update, user_1_token, raw_post_data: {first_name: "Jerry", last_name: "Mouse"}, 
                                     parameters: {id: user_2.id}
      expect(response.code).to eq('403')
      user_2.reload
      expect(user_2.first_name).to eq 'Bob'
      expect(user_2.last_name).to eq 'Michaels'
    end

    it "should let a trusted app update a user" do
      api_put :update, trusted_application_token, 
                       raw_post_data: {first_name: "Jerry", last_name: "Mouse"}, 
                       parameters: {id: user_2.id}
      expect(response.code).to eq('204')
      user_2.reload
      expect(user_2.first_name).to eq 'Jerry'
      expect(user_2.last_name).to eq 'Mouse'
    end

    it "should not let a user's contact info be modified through the users API" do
      original_contact_infos = user_2.contact_infos
      api_put :update, trusted_application_token, 
                       raw_post_data: {
                         first_name: "Jerry", 
                         last_name: "Mouse", 
                         contact_infos: [
                           {
                             id: user_2.contact_infos.first.id,
                             value: "howdy@doody.com"
                           }
                         ]                         
                       }, 
                       parameters: {id: user_2.id}
      expect(response.code).to eq('204')
      user_2.reload
      expect(user_2.contact_infos).to eq original_contact_infos
    end

  end

end
