require "spec_helper"

describe Api::V1::GroupsController, :type => :api, :version => :v1 do

  let!(:group_1) { FactoryGirl.create :group, name: 'Group 1',
                                      members_count: 0, owners_count: 0 }
  let!(:group_2) { FactoryGirl.create :group, name: 'Group 2',
                                      members_count: 0, owners_count: 0 }
  let!(:group_3) { FactoryGirl.create :group, name: 'Group 3',
                                      members_count: 0, owners_count: 0, is_public: true }

  let!(:user_1)       { FactoryGirl.create :user, :terms_agreed }
  let!(:user_2)       { FactoryGirl.create :user, :terms_agreed }

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
    it 'must list the visible groups for the current user' do
      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 3',
        'is_public' => true,
        'members' => [], 'owners' => [], 'groups' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_1.add_member(user_1)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'owners' => [], 'groups' => []
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => [], 'owners' => [], 'groups' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.add_member(group_3)
      group_2.reload
      group_3.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'owners' => [], 'groups' => []
      },
      {
        'container_group_id' => group_2.id,
        'name' => 'Group 3',
        'is_public' => true,
        'members' => [], 'owners' => [], 'groups' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_3.container_group = nil
      group_3.save!
      group_2.reload
      group_3.reload
      group_3.add_member(group_2)
      group_2.reload
      group_3.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ],
        'owners' => [], 'groups' => []
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => [], 'owners' => [], 'groups' => [
          {
            'container_group_id' => group_3.id, 
            'name' => 'Group 2',
            'is_public' => false,
            'members' => [], 'owners' => [], 'groups' => []
          }
        ]
      }]

      group_3.add_member(user_2)
      group_2.reload
      group_3.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'owners' => [], 'groups' => []
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => [
          {'id' => user_2.id, 'username' => user_2.username}
        ], 'owners' => [], 'groups' => [
          {
            'container_group_id' => group_3.id, 
            'name' => 'Group 2',
            'is_public' => false,
            'members' => [], 'owners' => [], 'groups' => []
          }
        ]
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.add_member(user_1)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'owners' => [], 'groups' => []
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => [
          {'id' => user_2.id, 'username' => user_2.username}
        ], 'owners' => [], 'groups' => [
          {
            'container_group_id' => group_3.id, 
            'name' => 'Group 2',
            'is_public' => false,
            'members' => [
              {'id' => user_1.id, 'username' => user_1.username}
            ], 'owners' => [], 'groups' => []
          }
        ]
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.container_group = nil
      group_2.save!
      group_2.reload
      group_3.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'owners' => [], 'groups' => []
      },
      {
        'name' => 'Group 2',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'owners' => [], 'groups' => []
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => [
          {'id' => user_2.id, 'username' => user_2.username}
        ], 'owners' => [], 'groups' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end

  context 'show' do
    it 'must always show public groups' do
      api_get :show, nil, parameters: {id: group_3.id}

      expect(response.code).to eq('200')
      expected_response = {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => [], 'owners' => [], 'groups' => []
      }
      expect(JSON.parse(response.body)).to eq(expected_response)
    end

    it 'must not show a private group without a token' do
      expect{api_get :show, nil, parameters: {id: group_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must not show a private group to an app without a user token' do
      expect{api_get :show, untrusted_application_token, parameters: {id: group_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must not show a private group to an unauthorized user' do
      expect{api_get :show, user_1_token, parameters: {id: group_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must show private groups to authorized users' do
      group_1.add_member(user_1)
      api_get :show, user_1_token, parameters: {id: group_1.id}

      expect(response.code).to eq('200')
      expected_response = {
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ],
        'owners' => [], 'groups' => []
      }
      expect(JSON.parse(response.body)).to eq(expected_response)

      group_1.add_member(group_2)
      GroupMember.last.destroy
      group_1.add_owner(user_1)
      api_get :show, user_1_token, parameters: {id: group_1.id}

      expect(response.code).to eq('200')
      expected_response = {
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [], 'owners' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'groups' => [
          {
            'container_group_id' => group_1.id,
            'name' => 'Group 2',
            'is_public' => false,
            'members' => [], 'owners' => [], 'groups' => []
          }
        ]
      }

      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end

  context 'create' do
    it 'must not create a group without a token' do
      expect{api_post :create, nil}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must not create a group for an app without a user token' do
      expect{api_post :create, untrusted_application_token}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must create groups for users' do
      api_post :create, user_1_token, raw_post_data: {name: 'MyGroup'}

      expect(response.code).to eq('201')
      expected_response = {
        'name' => 'MyGroup',
        'is_public' => false,
        'members' => [],
        'owners' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'groups' => []
      }
      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end

  context 'update' do
    it 'must not update a group without a token' do
      expect{api_put :update, nil,
                     parameters: {id: group_3.id},
                     raw_post_data: {name: 'MyGroup'}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(group_3.reload.name).to eq('Group 3')
    end

    it 'must not update a group for an app without a user token' do
      expect{api_put :update, untrusted_application_token,
                     parameters: {id: group_3.id},
                     raw_post_data: {name: 'MyGroup'}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(group_3.reload.name).to eq('Group 3')
    end

    it 'must not update a group for an unauthorized user' do
      expect{api_put :update, user_1_token,
                     parameters: {id: group_3.id},
                     raw_post_data: {name: 'MyGroup'}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(group_3.reload.name).to eq('Group 3')

      group_3.add_member(user_1)

      expect{api_put :update, user_1_token,
                     parameters: {id: group_3.id},
                     raw_post_data: {name: 'MyGroup'}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(group_3.reload.name).to eq('Group 3')

      group_3.add_member(group_2)
      group_2.add_owner(user_1)

      expect{api_put :update, user_1_token,
                     parameters: {id: group_3.id},
                     raw_post_data: {name: 'MyGroup'}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(group_3.reload.name).to eq('Group 3')
    end

    it 'must update groups for authorized users' do
      group_3.add_owner(user_1)
      api_put :update, user_1_token,
              parameters: {id: group_3.id},
              raw_post_data: {name: 'MyGroup'}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(group_3.reload.name).to eq('MyGroup')
    end
  end

  context 'destroy' do
    it 'must not destroy a group without a token' do
      expect{api_delete :destroy, nil,
                        parameters: {id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(Group.where(id: group_3.id).first).not_to be_nil
    end

    it 'must not destroy a group for an app without a user token' do
      expect{api_delete :destroy, untrusted_application_token,
                        parameters: {id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(Group.where(id: group_3.id).first).not_to be_nil
    end

    it 'must not destroy a group for an unauthorized user' do
      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(Group.where(id: group_3.id).first).not_to be_nil

      group_3.add_member(user_1)

      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(Group.where(id: group_3.id).first).not_to be_nil

      group_3.add_member(group_2)
      group_2.add_owner(user_1)

      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(Group.where(id: group_3.id).first).not_to be_nil
    end

    it 'must destroy groups for authorized users' do
      group_3.add_owner(user_1)
      api_delete :destroy, user_1_token,
                 parameters: {id: group_3.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(Group.where(id: group_3.id).first).to be_nil
    end
  end

end
