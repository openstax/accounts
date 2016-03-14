require 'rails_helper'

describe Api::V1::UsersController, type: :controller, api: true, version: :v1 do

  let!(:untrusted_application)     { FactoryGirl.create :doorkeeper_application }
  let!(:trusted_application)     { FactoryGirl.create :doorkeeper_application, :trusted }
  let!(:user_1)          { FactoryGirl.create :user, :terms_agreed }
  let!(:user_2)          { FactoryGirl.create :user_with_emails, :terms_agreed, first_name: 'Bob', last_name: 'Michaels' }
  let!(:unclaimed_user)  { FactoryGirl.create :user_with_emails, state:'unclaimed' }
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
        total_count: 1,
        items: [
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

      expect(outcome["items"].length).to eq 3
      expect(outcome["items"][0]["username"]).to eq "foo_bj"
      expect(outcome["items"][1]["username"]).to eq "foo_bb"
      expect(outcome["items"][2]["username"]).to eq "foo_tj"
    end

    it "should return no results if the maximum number of results is exceeded" do
      api_get :index, trusted_application_token, parameters: {q: ''}
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["items"].length).to eq 0
      expect(outcome["total_count"]).not_to eq 0
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
      expect(response.code).to eq('200')
      user_2.reload
      expect(user_2.first_name).to eq 'Jerry'
      expect(user_2.last_name).to eq 'Mouse'
    end

    it "should not let id be specified" do
      api_put :update, user_2_token, raw_post_data: {first_name: "Jerry", last_name: "Mouse"}, parameters: {id: admin_user.id}
      expect(response.code).to eq('200')
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
      original_contact_infos = user_2.reload.contact_infos
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
      expect(response.code).to eq('200')
      user_2.reload
      expect(user_2.contact_infos).to eq original_contact_infos
    end

  end

  describe "find or create" do
    it "should create a new user for an app" do
      expect{
        api_post :find_or_create,
                 trusted_application_token,
                 raw_post_data: {email: 'a-new-email@test.com'}
      }.to change{User.count}.by(1)
      expect(response.code).to eq('200')
      new_user_id = User.order(:id).last.id
      expect(response.body).to eq({id: new_user_id}.to_json)
    end

    it 'creates a new user with first name, last name and full name if given' do
      expect {
        api_post :find_or_create,
                 trusted_application_token,
                 raw_post_data: {
                   email: 'a-new-email@test.com',
                   first_name: 'Sarah',
                   last_name: 'Test',
                   full_name: 'Sarah M. Test'
                 }
      }.to change { User.count }.by(1)
      expect(response.code).to eq('200')
      new_user = User.find(JSON.parse(response.body)['id'])
      expect(new_user.first_name).to eq 'Sarah'
      expect(new_user.last_name).to eq 'Test'
      expect(new_user.full_name).to eq 'Sarah M. Test'
    end

    it "should not create a new user for anonymous" do
      user_count = User.count
      expect{
        api_post :find_or_create,
                 nil,
                 raw_post_data: {email: 'a-new-email@test.com'}
      }.to raise_error(SecurityTransgression)
      expect(User.count).to eq user_count
    end

    it "should not create a new user for another user" do
      user_count = User.count
      expect{
        api_post :find_or_create,
                 user_2_token,
                 raw_post_data: {email: 'a-new-email@test.com'}
      }.to raise_error(SecurityTransgression)
      expect(User.count).to eq user_count
    end

    context "should return only an id for an user" do
      it "does so for unclaimed users" do
        api_post :find_or_create, trusted_application_token,
                 raw_post_data: {email: unclaimed_user.contact_infos.first.value}
        expect(response.code).to eq('200')
        expect(response.body).to eq({id: unclaimed_user.id}.to_json)
      end
      it "does so for claimed users" do
        api_post :find_or_create,
                 trusted_application_token,
                 raw_post_data: {email: user_2.contact_infos.first.value}
        expect(response.code).to eq('200')
        expect(response.body).to eq({id: user_2.id}.to_json)
      end
    end

  end
end
