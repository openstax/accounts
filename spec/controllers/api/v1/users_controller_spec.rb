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

  describe "search" do

    it "returns a single result well" do
      api_get :search, trusted_application_token, {q: 'first_name:bob, last_name:Michaels'}
      expect(response.code).to eq('200')

      expected_response = {
        num_matching_users: 1,
        page: 0,
        per_page: 20,
        order_by: 'username ASC',
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

    let!(:billy_users) {
      (0..45).to_a.collect{|ii|
        FactoryGirl.create :user, 
                           first_name: "Billy#{ii.to_s.rjust(2, '0')}",
                           last_name: "Fred_#{(45-ii).to_s.rjust(2,'0')}",
                           username: "billy_#{ii.to_s.rjust(2, '0')}"
      }
    }

    it "should return the 2nd page when requested" do
      api_get :search, trusted_application_token, {q: 'username:billy', page: 1, per_page: 10}

      outcome = JSON.parse(response.body)

      expect(outcome["num_matching_users"]).to eq 46
      expect(outcome["users"].length).to eq 10
      expect(outcome["users"][0]["username"]).to eq "billy_10"
      expect(outcome["users"][9]["username"]).to eq "billy_19"
    end

    it "should return the incomplete 3rd page when requested" do
      # outcome = SearchUsers.call("username:billy", page: 2).outputs.users.all
      # expect(outcome.length).to eq 6
      # expect(outcome[5]).to eq User.where{username.eq "billy_45"}.first
    end

    let!(:bob_brown) { FactoryGirl.create :user, first_name: "Bob", last_name: "Brown", username: "foo_bb" }
    let!(:bob_jones) { FactoryGirl.create :user, first_name: "Bob", last_name: "Jones", username: "foo_bj" }
    let!(:tim_jones) { FactoryGirl.create :user, first_name: "Tim", last_name: "Jones", username: "foo_tj" }

    it "should allow sort by multiple fields in different directions" do
      api_get :search, trusted_application_token, {q: 'username:foo', order_by: "first_name, last_name DESC"}

      outcome = JSON.parse(response.body)

      expect(outcome["users"].length).to eq 3
      expect(outcome["users"][0]["username"]).to eq "foo_bj"
      expect(outcome["users"][1]["username"]).to eq "foo_bb"
      expect(outcome["users"][2]["username"]).to eq "foo_tj"
      expect(outcome["order_by"]).to eq "first_name ASC, last_name DESC"
    end


  end

end
