require 'rails_helper'

describe Api::V1::ApplicationGroupsController, type: :controller, api: true, version: :v1 do

  let!(:untrusted_application) { FactoryGirl.create :doorkeeper_application }
  let!(:trusted_application)   { FactoryGirl.create :doorkeeper_application, :trusted }
  let!(:user_1) { FactoryGirl.create :user }
  let!(:user_2) { FactoryGirl.create :user_with_emails,
                                     first_name: 'Bob',
                                     last_name: 'Michaels' }

  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
    application: untrusted_application,
    resource_owner_id: user_2.id }

  let!(:untrusted_application_token) { FactoryGirl.create :doorkeeper_access_token,
    application: untrusted_application,
    resource_owner_id: nil }
  let!(:trusted_application_token)   { FactoryGirl.create :doorkeeper_access_token,
    application: trusted_application,
    resource_owner_id: nil }

  let!(:group_1) { FactoryGirl.create :group, members_count: 0, owners_count: 0 }
  let!(:group_2) { FactoryGirl.create :group, members_count: 0, owners_count: 0 }
  let!(:application_group_1) { FactoryGirl.create :application_group,
                                                  application: untrusted_application,
                                                  group: group_1 }
  let!(:application_group_2) { FactoryGirl.create :application_group,
                                                  application: trusted_application,
                                                  group: group_2 }

  describe "updates" do

    it "should return no results for an app without updated groups" do
      api_get :updates, untrusted_application_token

      expected_response = [].to_json

      expect(response.body).to eq(expected_response)

      group_1.name = 'G'
      group_1.save!

      api_get :updates, untrusted_application_token

      expected_response = [].to_json

      expect(response.body).to eq(expected_response)

      group_1.is_public = true
      group_1.save!

      application_group_1.reload.unread_updates = 0
      application_group_1.save!

      expect(application_group_1.reload.unread_updates).to eq 0

      api_get :updates, untrusted_application_token

      expect(application_group_1.reload.unread_updates).to eq 0

      expected_response = [].to_json

      expect(response.body).to eq(expected_response)
    end

    it "should return properly formatted JSON responses" do
      group_1.save!
      application_group_1.reload.unread_updates = 0
      application_group_1.save!

      expect(application_group_1.reload.unread_updates).to eq 0

      group_1.name = 'G'
      group_1.save!

      expect(application_group_1.reload.unread_updates).to eq 1

      api_get :updates, untrusted_application_token

      expected_response = [].to_json

      expect(response.body).to eq(expected_response)

      group_1.is_public = true
      group_1.save!

      expect(application_group_1.reload.unread_updates).to eq 2

      api_get :updates, untrusted_application_token

      expect(application_group_1.reload.unread_updates).to eq 2

      expected_response = [{
        id: application_group_1.id,
        group: {
          id: group_1.id,
          name: 'G',
          is_public: true,
          owners: [],
          members: [],
          nestings: [],
          supertree_group_ids: [group_1.id],
          subtree_group_ids: [group_1.id],
          subtree_member_ids: []
        },
        unread_updates: 2
      }].to_json

      expect(response.body).to eq(expected_response)

      api_get :updates, untrusted_application_token

      expect(response.body).to eq(expected_response)

      FactoryGirl.create :group_nesting, container_group: group_1,
                                         member_group: group_2

      expect(application_group_1.reload.unread_updates).to eq 3

      group_2.add_owner(user_1)

      expect(application_group_1.reload.unread_updates).to eq 3

      api_get :updates, untrusted_application_token

      expect(application_group_1.reload.unread_updates).to eq 3

      application_group_2 = ApplicationGroup.last

      expected_response = [{
        id: application_group_1.id,
        group: {
          id: group_1.id,
          name: 'G',
          is_public: true,
          owners: [],
          members: [],
          nestings: [
            {
              container_group_id: group_1.id,
              member_group_id: group_2.id
            }
          ],
          supertree_group_ids: [group_1.id],
          subtree_group_ids: [group_1.id, group_2.id],
          subtree_member_ids: []
        },
        unread_updates: 3
      },
      {
        id: application_group_2.id,
        group: {
          id: group_2.id,
          is_public: false,
          owners: [
            {group_id: group_2.id,
             user: {id: user_1.id, username: user_1.username}}
          ],
          members: [],
          nestings: [],
          supertree_group_ids: [group_2.id, group_1.id],
          subtree_group_ids: [group_2.id],
          subtree_member_ids: []
        }, unread_updates: 1
      }].to_json

      expect(response.body).to eq(expected_response)

      application_group_1.reload.unread_updates = 0
      application_group_1.save!
      application_group_2.reload.unread_updates = 0
      application_group_2.save!

      api_get :updates, untrusted_application_token
      expected_response = [].to_json

      expect(response.body).to eq(expected_response)
    end

    it "should not let a user call it through an app" do
      expect{api_get :updates, user_2_token}.to raise_error(SecurityTransgression)
    end

  end

  describe "updated" do
    it "should properly change unread_updates" do
      group_1.save!
      application_group_1.reload.unread_updates = 2
      application_group_1.save!

      expect(application_group_1.reload.unread_updates).to eq 2

      group_1.name = 'G'
      group_1.save!

      expect(application_group_1.reload.unread_updates).to eq 3

      group_1.name = 'Group'
      group_1.save!

      expect(application_group_1.reload.unread_updates).to eq 4

      api_put :updated, untrusted_application_token, raw_post_data: [
        {group_id: group_1.id, read_updates: 2}].to_json

      expect(response.status).to eq(204)

      expect(application_group_1.reload.unread_updates).to eq 4

      api_put :updated, untrusted_application_token, raw_post_data: [
        {group_id: group_1.id, read_updates: 1}].to_json

      expect(response.status).to eq(204)

      expect(application_group_1.reload.unread_updates).to eq 4

      api_put :updated, untrusted_application_token, raw_post_data: [
        {group_id: group_1.id, read_updates: 4}].to_json

      expect(response.status).to eq(204)

      expect(application_group_1.reload.unread_updates).to eq 0
    end

    it "should not let an app mark another app's updates as read" do
      expect(application_group_1.reload.unread_updates).to eq 1

      api_put :updated, trusted_application_token,
              raw_post_data: [{id: application_group_1.id, read_updates: 1}].to_json

      expect(application_group_1.reload.unread_updates).to eq 1
    end

    it "should not let a user call it through an app" do
      expect{api_get :updates, user_2_token}.to raise_error(SecurityTransgression)
      expect{api_put :updated, user_2_token}.to raise_error(SecurityTransgression)
    end

  end

end
