require "spec_helper"

describe Api::V1::UsersController, :type => :api, :version => :v1 do

  let!(:untrusted_application)     { FactoryGirl.create :doorkeeper_application }
  let!(:trusted_application)     { FactoryGirl.create :doorkeeper_application, :trusted }
  let!(:user_1)          { FactoryGirl.create :user, :terms_agreed }
  let!(:user_2)          { FactoryGirl.create :user_with_emails, :terms_agreed, first_name: 'Bob', last_name: 'Michaels' }
  let!(:admin_user)      { FactoryGirl.create :user, :terms_agreed, :admin }

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


  let!(:billy_users) {
    (0..45).to_a.collect{|ii|
      FactoryGirl.create :user,
                         first_name: "Billy#{ii.to_s.rjust(2, '0')}",
                         last_name: "Fred_#{(45-ii).to_s.rjust(2,'0')}",
                         username: "billy_#{ii.to_s.rjust(2, '0')}"
    }
  }

  let!(:bob_brown) { FactoryGirl.create :user, first_name: "Bob", last_name: "Brown", username: "foo_bb" }
  let!(:bob_jones) { FactoryGirl.create :user, first_name: "Bob", last_name: "Jones", username: "foo_bj" }
  let!(:tim_jones) { FactoryGirl.create :user, first_name: "Tim", last_name: "Jones", username: "foo_tj" }

  describe "index" do

    it "returns a single result well" do
      api_get :index, trusted_application_token, parameters: {q: 'first_name:bob last_name:Michaels'}
      expect(response.code).to eq('200')

      expected_response = {
        num_matching_users: 1,
        order_by: 'username ASC',
        users: [
          {
            id: user_2.id,
            username: user_2.username,
            first_name: user_2.first_name,
            last_name: user_2.last_name
          }
        ]
      }.to_json

      expect(response.body).to eq(expected_response)
    end

    it "should allow sort by multiple fields in different directions" do
      api_get :index, trusted_application_token, parameters: {q: 'username:foo', order_by: "first_name, last_name DESC"}

      outcome = JSON.parse(response.body)

      expect(outcome["users"].length).to eq 3
      expect(outcome["users"][0]["username"]).to eq "foo_bj"
      expect(outcome["users"][1]["username"]).to eq "foo_bb"
      expect(outcome["users"][2]["username"]).to eq "foo_tj"
      expect(outcome["order_by"]).to eq "first_name ASC, last_name DESC"
    end

    it "should return no results if the maximum number of results is exceeded" do
      api_get :index, trusted_application_token, parameters: {q: ''}
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["users"].length).to eq 0
      expect(outcome["num_matching_users"]).to eq 56
    end

  end

  describe "show" do

    it "should let a User get his info" do
      api_get :show, user_1_token
      expect(response.code).to eq('200')
    end
    
    it "should not let id be specified" do
      api_get :show, user_1_token, parameters: {id: admin_user.id}
      
      expected_response = {
        id: user_1.id,
        username: user_1.username
      }.to_json
      
      expect(response.body).to eq(expected_response)
    end

    it "should not let an application get a User without a token" do
      expect {api_get :show, trusted_application_token, parameters: {id: admin_user.id}}.to raise_error(SecurityTransgression)
    end

    it "should return a properly formatted JSON response for low-info user" do
      api_get :show, user_1_token

      expected_response = {
        id: user_1.id,
        username: user_1.username
      }.to_json

      expect(response.body).to eq(expected_response)
    end

    it "should return a properly formatted JSON response for user with name" do
      api_get :show, user_2_token

      expected_response = {
        id: user_2.id,
        username: user_2.username,
        first_name: user_2.first_name,
        last_name: user_2.last_name
      }.to_json

      expect(response.body).to eq(expected_response)
    end

  end

  describe "update" do
    it "should let User update his own User" do
      api_put :update, user_2_token, raw_post_data: {first_name: "Jerry", last_name: "Mouse"}
      expect(response.code).to eq('204')
      user_2.reload
      expect(user_2.first_name).to eq 'Jerry'
      expect(user_2.last_name).to eq 'Mouse'
    end

    it "should not let id be specified" do
      api_put :update, user_2_token, raw_post_data: {first_name: "Jerry", last_name: "Mouse"}, parameters: {id: admin_user.id}
      expect(response.code).to eq('204')
      user_2.reload
      admin_user.reload
      expect(user_2.first_name).to eq 'Jerry'
      expect(user_2.last_name).to eq 'Mouse'
      expect(admin_user.first_name).not_to eq 'Jerry'
      expect(admin_user.last_name).not_to eq 'Mouse'
    end

    it "should not let an application update a User without a token" do
      expect{api_put :update, trusted_application_token, parameters: {id: admin_user.id}}.to raise_error(SecurityTransgression)
    end

    it "should not let a user's contact info be modified through the users API" do
      original_contact_infos = user_2.contact_infos
      api_put :update, user_2_token,
                       raw_post_data: {
                         first_name: "Jerry", 
                         last_name: "Mouse", 
                         contact_infos: [
                           {
                             id: user_2.contact_infos.first.id,
                             value: "howdy@doody.com"
                           }
                         ]                         
                       }
      expect(response.code).to eq('204')
      user_2.reload
      expect(user_2.contact_infos).to eq original_contact_infos
    end

  end

end
