require 'rails_helper'

describe Api::V1::GroupOwnersController, type: :controller, api: true, version: :v1 do

  let!(:group_1) { FactoryGirl.create :group, name: 'Group 1',
                                      members_count: 0, owners_count: 0 }
  let!(:group_2) { FactoryGirl.create :group, name: 'Group 2',
                                      members_count: 0, owners_count: 0 }
  let!(:group_3) { FactoryGirl.create :group, name: 'Group 3',
                                      members_count: 0, owners_count: 0, is_public: true }

  let!(:user_1)       { FactoryGirl.create :user, :terms_agreed }
  let!(:user_2)       { FactoryGirl.create :user, :terms_agreed }

  let!(:group_owner_1) { FactoryGirl.create :group_owner, group: group_2, user: user_2 }

  let!(:untrusted_application) { FactoryGirl.create :doorkeeper_application }

  let!(:user_1_token) { FactoryGirl.create :doorkeeper_access_token,
                        application: untrusted_application,
                        resource_owner_id: user_1.id }
  let!(:user_2_token) { FactoryGirl.create :doorkeeper_access_token,
                        application: untrusted_application,
                        resource_owner_id: user_2.id }
  let!(:untrusted_application_token) { FactoryGirl.create :doorkeeper_access_token,
                                       application: untrusted_application,
                                       resource_owner_id: nil }

  context 'index' do
    it 'must not list group ownerships without a token' do
      api_get :index, nil

      expect(response).to have_http_status :forbidden
    end

    it 'must not list group ownerships for an app without a user token' do
      api_get :index, untrusted_application_token

      expect(response).to have_http_status :forbidden
    end

    it 'must list all group ownerships for human users' do
      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = []

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_1.add_owner(user_1)
      controller.current_human_user.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [
        {
          'user_id' => user_1.id,
          'group' => {
            'id' => group_1.id,
            'name' => 'Group 1',
            'is_public' => false,
            'owners' => [
              {
                'group_id' => group_1.id,
                'user' => user_hash(user_1)
              }
            ],
            'members' => [],
            'nestings' => [],
            'supertree_group_ids' => [group_1.id],
            'subtree_group_ids' => [group_1.id],
            'subtree_member_ids' => []
          }
        }
      ]

      expect(JSON.parse(response.body)).to eq(expected_response)

      FactoryGirl.create(:group_nesting, container_group: group_1, member_group: group_2)
      controller.current_human_user.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')

      group_1.reload
      group_1_json = {
        'user_id' => user_1.id,
        'group' => {
          'id' => group_1.id,
          'name' => 'Group 1',
          'is_public' => false,
          'owners' => [
            {
              'group_id' => group_1.id,
              'user' => user_hash(user_1)
            }
          ],
          'members' => [],
          'nestings' => [
            {
              'container_group_id' => group_1.id,
              'member_group_id' => group_2.id,
            }
          ],
          'supertree_group_ids' => [group_1.id],
          'subtree_group_ids' => group_1.subtree_group_ids,
          'subtree_member_ids' => []
        }
      }

      expected_response = [group_1_json]

      expect(JSON.parse(response.body)).to eq(expected_response)
      expect(group_1.subtree_group_ids).to include(group_1.id)
      expect(group_1.subtree_group_ids).to include(group_2.id)

      group_2.add_owner(user_1)
      controller.current_human_user.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')

      group_2.reload
      group_2_json = {
        'user_id' => user_1.id,
        'group' => {
          'id' => group_2.id,
          'name' => 'Group 2',
          'is_public' => false,
          'owners' => a_collection_containing_exactly(
            *group_2.group_owners.map do |group_owner|
              {
                'group_id' => group_2.id,
                'user' => user_hash(group_owner.user)
              }
            end
          ),
          'members' => [],
          'nestings' => [],
          'supertree_group_ids' => group_2.supertree_group_ids,
          'subtree_group_ids' => [group_2.id],
          'subtree_member_ids' => []
        }
      }

      expect(JSON.parse(response.body)).to include(group_1_json)
      expect(JSON.parse(response.body)).to include(group_2_json)
      expect(group_1.subtree_group_ids).to include(group_1.id)
      expect(group_1.subtree_group_ids).to include(group_2.id)
      expect(group_2.supertree_group_ids).to include(group_1.id)
      expect(group_2.supertree_group_ids).to include(group_2.id)
      expect(group_2.owners).to include(user_1)
      expect(group_2.owners).to include(user_2)

      group_3.add_owner(user_1)
      controller.current_human_user.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')

      group_3.reload
      group_3_json = {
        'user_id' => user_1.id,
        'group' => {
          'id' => group_3.id,
          'name' => 'Group 3',
          'is_public' => true,
          'owners' => [
            {
              'group_id' => group_3.id,
              'user' => user_hash(user_1)
            }
          ],
          'members' => [],
          'nestings' => [],
          'supertree_group_ids' => [group_3.id],
          'subtree_group_ids' => [group_3.id],
          'subtree_member_ids' => []
        }
      }

      expect(JSON.parse(response.body)).to include(group_1_json)
      expect(JSON.parse(response.body)).to include(group_2_json)
      expect(JSON.parse(response.body)).to include(group_3_json)
    end
  end

  context 'create' do
    it 'must not create a group_owner without a token' do
      api_post :create, nil, parameters: {group_id: group_3.id, user_id: user_2.id}

      expect(response).to have_http_status :forbidden
    end

    it 'must not create a group_owner for an app without a user token' do
      api_post :create, untrusted_application_token,
                        parameters: { group_id: group_3.id, user_id: user_2.id }

      expect(response).to have_http_status :forbidden
    end

    it 'must not create a group_owner for an unauthorized user' do
      api_post :create, user_1_token, parameters: { group_id: group_3.id, user_id: user_2.id }

      expect(response).to have_http_status :forbidden

      group_3.add_member(user_1)
      controller.current_human_user.reload

      api_post :create, user_1_token, parameters: { group_id: group_3.id, user_id: user_2.id }

      expect(response).to have_http_status :forbidden
    end

    it 'must create group_owners for authorized users' do
      group_3.add_owner(user_1)
      api_post :create, user_1_token, parameters: { group_id: group_3.id, user_id: user_2.id }

      expect(response.code).to eq('201')
      expected_response = {
        'user_id' => user_2.id,
        'group' => {
          'id' => group_3.id,
          'name' => 'Group 3',
          'is_public' => true,
          'owners' => a_collection_containing_exactly(
            *group_3.owners.map do |owner|
              {
                'group_id' => group_3.id,
                'user' => user_hash(owner)
              }
            end
          ),
          'members' => [],
          'nestings' => [],
          'supertree_group_ids' => [group_3.id],
          'subtree_group_ids' => [group_3.id],
          'subtree_member_ids' => []
        }
      }

      expect(JSON.parse(response.body)).to include(expected_response)
      expect(group_3.owners).to include(user_1)
      expect(group_3.owners).to include(user_2)

      group_1.add_owner(user_1)
      api_post :create, user_1_token, parameters: { group_id: group_1.id, user_id: user_2.id }

      expect(response.code).to eq('201')
      expected_response = {
        'user_id' => user_2.id,
        'group' => {
          'id' => group_1.id,
          'name' => 'Group 1',
          'is_public' => false,
          'owners' => a_collection_containing_exactly(
            *group_1.owners.map do |owner|
              {
                'group_id' => group_1.id,
                'user' => user_hash(owner)
              }
            end
          ),
          'members' => [],
          'nestings' => [],
          'supertree_group_ids' => [group_1.id],
          'subtree_group_ids' => [group_1.id],
          'subtree_member_ids' => []
        }
      }
      expect(JSON.parse(response.body)).to include(expected_response)
      expect(group_1.owners).to include(user_1)
      expect(group_1.owners).to include(user_2)
    end
  end

  context 'destroy' do
    it 'must not destroy a group_owner without a token' do
      api_delete :destroy, nil, parameters: { group_id: group_2.id, user_id: user_2.id }

      expect(response).to have_http_status :forbidden
      expect(GroupOwner.where(id: group_owner_1.id).first).not_to be_nil
    end

    it 'must not destroy a group_owner for an app without a user token' do
      api_delete :destroy, untrusted_application_token,
                           parameters: { group_id: group_2.id, user_id: user_2.id }

      expect(response).to have_http_status :forbidden
      expect(GroupOwner.where(id: group_owner_1.id).first).not_to be_nil
    end

    it 'must not destroy a group_owner for an unauthorized user' do
      api_delete :destroy, user_1_token, parameters: { group_id: group_2.id, user_id: user_2.id }

      expect(response).to have_http_status :forbidden
      expect(GroupOwner.where(id: group_owner_1.id).first).not_to be_nil

      group_2.add_member(user_1)

      api_delete :destroy, user_1_token, parameters: { group_id: group_2.id, user_id: user_2.id }

      expect(response).to have_http_status :forbidden
      expect(GroupOwner.where(id: group_owner_1.id).first).not_to be_nil
    end

    it 'must destroy group_owners for authorized users' do
      group_2.add_owner(user_1)
      group_owner_2 = GroupOwner.last
      api_delete :destroy, user_1_token,
                 parameters: { group_id: group_2.id, user_id: user_1.id }

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupOwner.where(id: group_owner_2.id).first).to be_nil

      group_2.add_owner(user_1)
      api_delete :destroy, user_1_token,
                 parameters: { group_id: group_2.id, user_id: user_2.id }

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupOwner.where(id: group_owner_1.id).first).to be_nil
    end
  end

end
