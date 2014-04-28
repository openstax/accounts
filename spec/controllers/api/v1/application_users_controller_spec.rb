require "spec_helper"

describe Api::V1::ApplicationUsersController, :type => :api, :version => :v1 do

  let!(:untrusted_application)     { FactoryGirl.create :doorkeeper_application }
  let!(:trusted_application)     { FactoryGirl.create :doorkeeper_application, :trusted }
  let!(:user_1)          { FactoryGirl.create :user }
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

  before(:each) do
    FactoryGirl.create :application_user, user: user_2,
                       application: untrusted_application
    user_2.reload
  end

  describe "index" do

    it "returns a single result well" do
      api_get :index, untrusted_application_token, parameters: {q: 'first_name:bob last_name:Michaels'}
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
        ],
        application_users: [
          {
            id: user_2.application_users.first.id,
            application_id: untrusted_application.id,
            user: {
              id: user_2.id,
              username: user_2.username,
              first_name: user_2.first_name,
              last_name: user_2.last_name,
              contact_infos: user_2.contact_infos.collect{|ci| {id: ci.id, type: ci.type, value: ci.value, verified: ci.verified}}
            },
            unread_updates: 0
          }
        ]
      }.to_json

      expect(response.body).to eq(expected_response)
    end

    let!(:billy_users) {
      (0..45).to_a.collect{|ii|
        user = FactoryGirl.create :user,
                                  first_name: "Billy#{ii.to_s.rjust(2, '0')}",
                                  last_name: "Fred_#{(45-ii).to_s.rjust(2,'0')}",
                                  username: "billy_#{ii.to_s.rjust(2, '0')}"
        FactoryGirl.create :application_user, user: user,
                                              application: untrusted_application
      }
    }

    it "should return the 2nd page when requested" do
      api_get :index, untrusted_application_token, parameters: {q: 'username:billy', page: 1, per_page: 10}
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["num_matching_users"]).to eq 46
      expect(outcome["application_users"].length).to eq 10
      expect(outcome["application_users"][0]["user"]["username"]).to eq "billy_10"
      expect(outcome["application_users"][9]["user"]["username"]).to eq "billy_19"
    end

    it "should return the incomplete 5th page when requested" do
      api_get :index, untrusted_application_token, parameters: {q: 'username:billy', page: 4, per_page: 10}
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["num_matching_users"]).to eq 46
      expect(outcome["application_users"].length).to eq 6
      expect(outcome["application_users"][0]["user"]["username"]).to eq "billy_40"
      expect(outcome["application_users"][5]["user"]["username"]).to eq "billy_45"
    end

    let!(:bob_brown) { FactoryGirl.create :user, first_name: "Bob", last_name: "Brown", username: "foo_bb" }
    let!(:bob_jones) { FactoryGirl.create :user, first_name: "Bob", last_name: "Jones", username: "foo_bj" }
    let!(:tim_jones) { FactoryGirl.create :user, first_name: "Tim", last_name: "Jones", username: "foo_tj" }

    before(:each) do
      [bob_brown, bob_jones, tim_jones].each do |user|
        FactoryGirl.create :application_user, user: user,
                           application: untrusted_application
      end
    end

    it "should allow sort by multiple fields in different directions" do
      api_get :index, untrusted_application_token, parameters: {q: 'username:foo', order_by: "first_name, last_name DESC"}
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["application_users"].length).to eq 3
      expect(outcome["application_users"][0]["user"]["username"]).to eq "foo_bb"
      expect(outcome["application_users"][1]["user"]["username"]).to eq "foo_bj"
      expect(outcome["application_users"][2]["user"]["username"]).to eq "foo_tj"
      expect(outcome["order_by"]).to eq "first_name ASC, last_name DESC"
    end

    it "should return only users that use an app" do
      api_get :index, trusted_application_token, parameters: {q: 'first_name:bob last_name:Michaels'}
      expect(response.code).to eq('200')

      expected_response = {
        num_matching_users: 0,
        page: 0,
        per_page: 20,
        order_by: 'username ASC',
        users: [],
        application_users: []
      }.to_json

      expect(response.body).to eq(expected_response)

      trusted_app_user = FactoryGirl.create :application_user,
                                            application: trusted_application,
                                            user: user_2

      api_get :index, trusted_application_token, parameters: {q: 'first_name:bob last_name:Michaels'}
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
        ],
        application_users: [
          {
            id: trusted_app_user.id,
            application_id: trusted_application.id,
            user: {
              id: user_2.id,
              username: user_2.username,
              first_name: user_2.first_name,
              last_name: user_2.last_name,
              contact_infos: user_2.contact_infos.collect{|ci| {id: ci.id, type: ci.type, value: ci.value, verified: ci.verified}}
            },
            unread_updates: 0
          }
        ]
      }.to_json

      expect(response.body).to eq(expected_response)
    end

  end

  describe "create" do
    it "should let an app create an application_user for a user" do
      expect {
        api_post :create, user_1_token
      }.to change{user_1.application_users(true).count}.from(0).to(1)
      expect(response.code).to eq('201')
    end
    
    it "should not let an app create an application_user by itself" do
      expect {
        api_post :create, untrusted_application_token
      }.not_to change{untrusted_application.application_users(true).count}
      expect(response.code).to eq('403')
    end
  end

#   describe "show" do
#     it "should let an app get its application_user" do
#       api_get :show, untrusted_application_token, parameters: { id: app_user.id }
#       expect(response.code).to eq('200')
#       expect(response.body).to eq({id: app_user.id, application_id: untrusted_application.id, user_id: app_user.user_id}.to_json)
#     end
# 
#     it "should let a user get his application_user" do
#       api_get :show, user_1_token, parameters: { id: app_user.id }
#       expect(response.code).to eq('200')
#       expect(response.body).to eq({id: app_user.id, application_id: app_user.application_id, user_id: user_1.id}.to_json)
#     end
#     
#     it "should not let an app get another app's application_user" do
#       api_get :show, trusted_application_token, parameters: { id: app_user.id }
#       expect(response.code).to eq('403')
#     end
# 
#     it "should not let a user get another user's application_user" do
#       api_get :show, user_2_token, parameters: { id: app_user.id }
#       expect(response.code).to eq('403')
#     end
#   end
# 
#   describe "update" do
#     it "should let an app update its own application_user" do
#       info = FactoryGirl.create :contact_info, user: user_1
# 
#       api_put :update, untrusted_application_token,
#               raw_post_data: {default_contact_info_id: info.id},
#               parameters: {id: app_user.id}
#       expect(response.code).to eq('204')
#       app_user.reload
#       expect(app_user.default_contact_info).to eq info
#     end
# 
#     it "should let a user update his application_user" do
#       info = FactoryGirl.create :contact_info, user: user_1
# 
#       api_put :update, user_1_token,
#               raw_post_data: {default_contact_info_id: info.id},
#               parameters: {id: app_user.id}
#       expect(response.code).to eq('204')
#       app_user.reload
#       expect(app_user.default_contact_info).to eq info
#     end
# 
#     it "should not let an app update another app's application_user" do
#       info = FactoryGirl.create :contact_info, user: user_1
# 
#       api_put :update, trusted_application_token,
#               raw_post_data: {default_contact_info_id: info.id},
#               parameters: {id: app_user.id}
#       expect(response.code).to eq('403')
#       app_user.reload
#       expect(app_user.default_contact_info).not_to eq info
#     end
# 
#     it "should not let a user update another user's application_user" do
#       info = FactoryGirl.create :contact_info, user: user_1
#       
#       api_put :update, user_2_token,
#               raw_post_data: {default_contact_info_id: info.id},
#               parameters: {id: app_user.id}
#       expect(response.code).to eq('403')
#       app_user.reload
#       expect(app_user.default_contact_info).not_to eq info
#     end
#   end
# 
#   describe "destroy" do
#     it "should let an app delete its application_user" do
#       expect {
#         api_delete :destroy, untrusted_application_token,
#                    parameters: { id: app_user.id }
#       }.to change{untrusted_application.application_users(true).count}.from(1).to(0)
#       
#       expect(response.code).to eq('204')
#     end
# 
#     it "should let a user delete his application_user" do
#       expect {
#         api_delete :destroy, user_1_token,
#         parameters: { id: app_user.id }
#       }.to change{user_1.application_users(true).count}.from(1).to(0)
#       
#       expect(response.code).to eq('204')
#     end
# 
#     it "should not let an app delete another app's application_user" do
#       expect {
#         api_delete :destroy, trusted_application_token,
#         parameters: { id: app_user.id }
#       }.not_to change{untrusted_application.application_users(true).count}
#       
#       expect(response.code).to eq('403')
#     end
# 
#     it "should not let a user delete another user's application_user" do
#       expect {
#         api_delete :destroy, user_2_token,
#         parameters: { id: app_user.id }
#       }.not_to change{user_1.application_users(true).count}
#       
#       expect(response.code).to eq('403')
#     end
#   end

  describe "updates" do

    it "should return no results for an app without updated users" do
      api_get :updates, untrusted_application_token

      expected_response = [].to_json

      expect(response.body).to eq(expected_response)
    end

    it "should return properly formatted JSON responses" do
      user_2.first_name = 'Bo'
      user_2.save!
      app_user = user_2.application_users.first

      expect(app_user.unread_updates).to eq 1

      api_get :updates, untrusted_application_token

      expected_response = [{
        id: app_user.id,
        application_id: untrusted_application.id,
        user: {
          id: user_2.id,
          username: user_2.username,
          first_name: user_2.first_name,
          last_name: user_2.last_name,
          contact_infos: user_2.contact_infos.collect{|ci| {id: ci.id, type: ci.type, value: ci.value, verified: ci.verified}}
        },
        unread_updates: 1
      }].to_json

      expect(response.body).to eq(expected_response)

      api_get :updates, untrusted_application_token

      expect(response.body).to eq(expected_response)

      user_2.first_name = 'Bob'
      user_2.save!

      expect(app_user.reload.unread_updates).to eq 2

      api_get :updates, untrusted_application_token

      expected_response = [{
        id: app_user.id,
        application_id: untrusted_application.id,
        user: {
          id: user_2.id,
          username: user_2.username,
          first_name: user_2.first_name,
          last_name: user_2.last_name,
          contact_infos: user_2.contact_infos.collect{|ci| {id: ci.id, type: ci.type, value: ci.value, verified: ci.verified}}
        },
        unread_updates: 2
      }].to_json

      expect(response.body).to eq(expected_response)

      app_user.unread_updates = 1
      app_user.save!

      api_get :updates, untrusted_application_token

      expected_response = [{
        id: app_user.id,
        application_id: untrusted_application.id,
        user: {
          id: user_2.id,
          username: user_2.username,
          first_name: user_2.first_name,
          last_name: user_2.last_name,
          contact_infos: user_2.contact_infos.collect{|ci| {id: ci.id, type: ci.type, value: ci.value, verified: ci.verified}}
        },
        unread_updates: 1
      }].to_json

      expect(response.body).to eq(expected_response)

      app_user.unread_updates = 0
      app_user.save!

      api_get :updates, untrusted_application_token
      expected_response = [].to_json

      expect(response.body).to eq(expected_response)
    end

    it "should not let a user call it through an app" do
      api_get :updates, user_1_token
      expect(response.status).to eq(403)
    end

  end

  describe "updated" do
    it "should return properly formatted JSON responses" do
      user_2.first_name = 'Bo'
      user_2.save!
      app_user = user_2.application_users.first

      expect(app_user.unread_updates).to eq 1

      user_2.first_name = 'Bob'
      user_2.save!

      expect(app_user.reload.unread_updates).to eq 2

      user_2.first_name = 'Bo'
      user_2.save!

      expect(app_user.reload.unread_updates).to eq 3

      api_put :updated, untrusted_application_token, parameters: {application_users: {app_user.id => 1}}

      expect(response.status).to eq(200)

      expect(app_user.reload.unread_updates).to eq 2

      api_put :updated, untrusted_application_token, parameters: {application_users: {app_user.id => 2}}

      expect(response.status).to eq(200)

      expect(app_user.reload.unread_updates).to eq 0

      api_put :updated, untrusted_application_token, parameters: {application_users: {app_user.id => 1}}

      expect(response.status).to eq(200)

      expect(app_user.reload.unread_updates).to eq 0
    end

    it "should not let an app mark another app's updates as read" do
      app_user = user_2.application_users.first
      api_put :updated, trusted_application_token, parameters: {application_users: {app_user.id => 1}}
      expect(response.status).to eq(403)
    end

    it "should not let a user call it through an app" do
      api_get :updates, user_1_token
      expect(response.status).to eq(403)
      api_put :updated, user_1_token
      expect(response.status).to eq(403)
    end

  end

end