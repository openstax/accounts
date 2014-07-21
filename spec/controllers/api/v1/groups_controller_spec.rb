require "spec_helper"

describe Api::V1::GroupsController, :type => :api, :version => :v1 do

  let!(:group_1) { FactoryGirl.create :group, name: 'Group 1', users_count: 0 }
  let!(:group_2) { FactoryGirl.create :group, name: 'Group 2', users_count: 0 }
  let!(:group_3) { FactoryGirl.create :group, name: 'Group 3', users_count: 0,
                                              is_public: true }

  let!(:user_1)       { FactoryGirl.create :user, :terms_agreed }
  let!(:user_2)       { FactoryGirl.create :user, :terms_agreed }
  let!(:user_3)       { FactoryGirl.create :user, :terms_agreed }

  let!(:untrusted_application) { FactoryGirl.create :doorkeeper_application }

  let!(:user_1_token) { FactoryGirl.create :doorkeeper_access_token,
                        application: untrusted_application,
                        resource_owner_id: user_1.id }
  let!(:user_2_token) { FactoryGirl.create :doorkeeper_access_token,
                        application: untrusted_application,
                        resource_owner_id: user_2.id }
  let!(:user_3_token) { FactoryGirl.create :doorkeeper_access_token,
                        application: untrusted_application,
                        resource_owner_id: user_3.id }
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
        'members' => {'users' => []},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_1.add_user(user_1)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => {'users' => []},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.add_permitted_group(group_1)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      },
      {
        'name' => 'Group 2',
        'is_public' => false,
        'members' => {'users' => []},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => [
          {'name' => 'Group 1', 'users' => [
            {'id' => user_1.id, 'username' => user_1.username}
          ]}
        ]}
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => {'users' => []},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.permitted_group_groups.first.destroy

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => {'users' => []},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      }]

      group_3.add_user(user_2)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => {'users' => [
          {'id' => user_2.id, 'username' => user_2.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
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
        'members' => {'users' => []},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
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
      group_1.add_user(user_1)
      api_get :show, user_1_token, parameters: {id: group_1.id}

      expect(response.code).to eq('200')
      expected_response = {
        'name' => 'Group 1',
        'is_public' => false,
        'members' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      }
      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.add_permitted_group(group_1)
      api_get :show, user_1_token, parameters: {id: group_2.id}

      expect(response.code).to eq('200')
      expected_response = {
        'name' => 'Group 2',
        'is_public' => false,
        'members' => {'users' => []},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => [
          {'name' => 'Group 1', 'users' => [
            {'id' => user_1.id, 'username' => user_1.username}
          ]}
        ]}
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
        'members' => {'users' => []},
        'owners' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
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

      group_3.add_user(user_1)

      expect{api_put :update, user_1_token,
                     parameters: {id: group_3.id},
                     raw_post_data: {name: 'MyGroup'}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(group_3.reload.name).to eq('Group 3')

      group_3.add_user(user_1, :manager)

      expect{api_put :update, user_1_token,
                     parameters: {id: group_3.id},
                     raw_post_data: {name: 'MyGroup'}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(group_3.reload.name).to eq('Group 3')
    end

    it 'must update groups for authorized users' do
      group_3.add_user(user_1, :owner)
      api_put :update, user_1_token,
              parameters: {id: group_3.id},
              raw_post_data: {name: 'MyGroup'}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(group_3.reload.name).to eq('MyGroup')

      group_1.add_user(user_1)
      group_2.add_permitted_group(group_1, :owner)
      api_put :update, user_1_token,
              parameters: {id: group_2.id},
              raw_post_data: {name: 'MyGroup2'}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(group_2.reload.name).to eq('MyGroup2')
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

      group_3.add_user(user_1)

      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(Group.where(id: group_3.id).first).not_to be_nil

      group_3.add_user(user_1, :manager)

      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(Group.where(id: group_3.id).first).not_to be_nil
    end

    it 'must destroy groups for authorized users' do
      group_3.add_user(user_1, :owner)
      api_delete :destroy, user_1_token,
                 parameters: {id: group_3.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(Group.where(id: group_3.id).first).to be_nil

      group_1.add_user(user_1)
      group_2.add_permitted_group(group_1, :owner)
      api_delete :destroy, user_1_token,
                 parameters: {id: group_2.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(Group.where(id: group_2.id).first).to be_nil
    end
  end

end
