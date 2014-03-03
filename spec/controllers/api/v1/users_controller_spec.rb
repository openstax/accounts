require "spec_helper"

describe Api::V1::UsersController, :type => :api, :version => :v1 do

  let!(:untrusted_application)     { FactoryGirl.create :doorkeeper_application }
  let!(:trusted_application)     { FactoryGirl.create :doorkeeper_application, :trusted }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_2)          { FactoryGirl.create :user_with_emails, first_name: 'Bob', last_name: 'Jones' }
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

  describe "GET" do

    it "should let User get his own User" do
      api_get :show, user_1_token, {id: user_1.id}
      expect(response.code).to eq('200')
    end

    it "should not let User get another User" do
      api_get :show, user_1_token, {id: user_2.id}
      expect(response.code).to eq('403')
    end

    it "should let an admin get another User" do
      api_get :show, admin_token, {id: user_2.id}
      expect(response.code).to eq('200')
    end

    it "should let a trusted application get a User" do
      api_get :show, trusted_application_token, {id: admin_user.id}
      expect(response.code).to eq('200')
    end

    it "should not let an untrusted application get a User" do
      api_get :show, untrusted_application_token, {id: user_1.id}
      expect(response.code).to eq('403')
    end

    it "should return a properly formatted JSON response for low-info user" do
      api_get :show, user_1_token, {id: user_1.id}
      
      expected_response = {
        id: user_1.id,
        username: user_1.username,
        contact_infos: []
      }.to_json

      expect(response.body).to eq(expected_response)
    end

    it "should return a properly formatted JSON response for user with name and contact infos" do
      api_get :show, user_2_token, {id: user_2.id}
      
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

  describe "search", :focus => true do

    it "returns a single result well" do
      api_get :search, trusted_application_token, {q: 'name:bob'}
      expect(response.code).to eq('200')

      expected_response = {
        num_matching_users: 1,
        page: 0,
        per_page: 20,
        users: [
          {
            id: user_2.id,
            username: user_2.username,
            first_name: user_2.first_name,
            last_name: user_2.last_name,
            contact_infos: user_2.contact_infos.collect{|ci| {id: ci.id, type: ci.type, value: ci.value, verified: ci.verified}}
          }
        ]
      }.to_json

      expect(response.body).to eq(expected_response)
    end

  end

end
