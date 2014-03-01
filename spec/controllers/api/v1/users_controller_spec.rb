require "spec_helper"

describe Api::V1::UsersController, :type => :api, :version => :v1 do

  describe "GET" do

    let!(:untrusted_application)     { FactoryGirl.create :doorkeeper_application }
    let!(:trusted_application)     { FactoryGirl.create :doorkeeper_application, :trusted }
    let!(:user_1)          { FactoryGirl.create :user }
    let!(:user_2)          { FactoryGirl.create :user }
    let!(:admin_user)      { FactoryGirl.create :user, :admin }

    let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token, 
                                                application: untrusted_application, 
                                                resource_owner_id: user_1.id }

    let!(:admin_token)       { FactoryGirl.create :doorkeeper_access_token, 
                                                  application: untrusted_application, 
                                                  resource_owner_id: admin_user.id }

    let!(:untrusted_application_token) { FactoryGirl.create :doorkeeper_access_token, 
                                                  application: untrusted_application, 
                                                  resource_owner_id: nil }

    let!(:trusted_application_token) { FactoryGirl.create :doorkeeper_access_token, 
                                                  application: trusted_application, 
                                                  resource_owner_id: nil }

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

    it "should return a properly formatted JSON response" do
      api_get :show, user_1_token, {id: user_1.id}
      
      expected_response = {
        id: user_1.id,
        username: user_1.username,
        first_name: user_1.first_name,
        last_name: user_1.last_name,
        full_name: user_1.full_name,
        title: user_1.title
      }.to_json

      expect(response.body).to eq(expected_response)
    end

  end

end
