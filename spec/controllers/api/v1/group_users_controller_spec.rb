require "spec_helper"

describe Api::V1::GroupUsersController, :type => :api, :version => :v1 do

  let!(:group_1) { FactoryGirl.create :group, name: 'Group 1', users_count: 0 }
  let!(:group_2) { FactoryGirl.create :group, name: 'Group 2', users_count: 0 }
  let!(:group_3) { FactoryGirl.create :group, name: 'Group 3', users_count: 0,
                                              is_public: true }

  let!(:user_1)       { FactoryGirl.create :user, :terms_agreed }
  let!(:user_2)       { FactoryGirl.create :user, :terms_agreed }

  let!(:group_user_1) { FactoryGirl.create :group_user, group: group_2,
                                           user: user_2, role: 'manager' }

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
    it 'must not list group memberships without a token' do
      expect{api_get :index, nil}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must not list group memberships for an app without a user token' do
      expect{api_get :index, untrusted_application_token}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must list all group memberships for human users' do
      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = []

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_1.add_user(user_1)
      controller.current_human_user.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{'group' => {
        'name' => 'Group 1',
        'is_public' => false,
        'members' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      }, 'user_id' => user_1.id, 'role' => 'member'}]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.add_permitted_group(group_1)
      controller.current_human_user.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{'group' => {
        'name' => 'Group 1',
        'is_public' => false,
        'members' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      }, 'user_id' => user_1.id, 'role' => 'member'}]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_1.add_user(user_2, :viewer)
      controller.current_human_user.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{'group' => {
        'name' => 'Group 1',
        'is_public' => false,
        'members' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [
          {'id' => user_2.id, 'username' => user_2.username}
        ], 'groups' => []}
      }, 'user_id' => user_1.id, 'role' => 'member'}]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_3.add_user(user_1, :owner)
      controller.current_human_user.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{'group' => {
        'name' => 'Group 1',
        'is_public' => false,
        'members' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [
          {'id' => user_2.id, 'username' => user_2.username}
        ], 'groups' => []}
      }, 'user_id' => user_1.id, 'role' => 'member'},
      {'group' => {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => {'users' => []},
        'owners' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      }, 'user_id' => user_1.id, 'role' => 'owner'}]

      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end

  context 'create' do
    it 'must not create a group_user without a token' do
      expect{api_post :create, nil, parameters: {group_id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must not create a group_user for an app without a user token' do
      expect{api_post :create, untrusted_application_token, parameters: {group_id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must not create a group_user for an unauthorized user' do
      expect{api_post :create, user_1_token, parameters: {group_id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty

      group_3.add_user(user_1)
      controller.current_human_user.reload

      expect{api_post :create, user_1_token, parameters: {group_id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty

      group_3.add_user(user_1, :viewer)
      controller.current_human_user.reload

      expect{api_post :create, user_1_token, parameters: {group_id: group_3.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must create group_users for authorized users' do
      group_3.add_user(user_1, :manager)
      api_post :create, user_1_token, parameters: {group_id: group_3.id},
               raw_post_data: {user_id: user_2.id, role: :member}

      expect(response.code).to eq('201')
      expected_response = {'group' => {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => {'users' => [
          {'id' => user_2.id, 'username' => user_2.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'groups' => []},
        'viewers' => {'users' => [], 'groups' => []}
      }, 'user_id' => user_2.id, 'role' => 'member'}
      expect(JSON.parse(response.body)).to eq(expected_response)

      group_1.add_user(user_1, :owner)
      api_post :create, user_1_token, parameters: {group_id: group_1.id},
               raw_post_data: {user_id: user_2.id, role: :viewer}

      expect(response.code).to eq('201')
      expected_response = {'group' => {
        'name' => 'Group 1',
        'is_public' => false,
        'members' => {'users' => []},
        'owners' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ], 'groups' => []},
        'managers' => {'users' => [], 'groups' => []},
        'viewers' => {'users' => [
          {'id' => user_2.id, 'username' => user_2.username}
        ], 'groups' => []}
      }, 'user_id' => user_2.id, 'role' => 'viewer'}
      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end

  context 'destroy' do
    before (:each) do

    end

    it 'must not destroy a group_user without a token' do
      expect{api_delete :destroy, nil,
                        parameters: {id: group_user_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupUser.where(id: group_user_1.id).first).not_to be_nil
    end

    it 'must not destroy a group for an app without a user token' do
      expect{api_delete :destroy, untrusted_application_token,
                        parameters: {id: group_user_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupUser.where(id: group_user_1.id).first).not_to be_nil
    end

    it 'must not destroy a group for an unauthorized user' do
      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_user_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupUser.where(id: group_user_1.id).first).not_to be_nil

      group_2.add_user(user_1)

      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_user_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupUser.where(id: group_user_1.id).first).not_to be_nil

      group_2.add_user(user_1, :viewer)

      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_user_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupUser.where(id: group_user_1.id).first).not_to be_nil

      group_2.add_user(user_1, :manager)

      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_user_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupUser.where(id: group_user_1.id).first).not_to be_nil
    end

    it 'must destroy group_users for authorized users' do
      group_2.add_user(user_1)
      group_user_2 = GroupUser.last
      api_delete :destroy, user_2_token,
                 parameters: {id: group_user_2.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupUser.where(id: group_user_2.id).first).to be_nil

      group_2.add_user(user_1, :viewer)
      group_user_3 = GroupUser.last
      api_delete :destroy, user_2_token,
                 parameters: {id: group_user_3.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupUser.where(id: group_user_3.id).first).to be_nil

      group_2.add_user(user_2, :owner)
      group_2.add_user(user_1, :manager)
      group_user_4 = GroupUser.last
      api_delete :destroy, user_2_token,
                 parameters: {id: group_user_4.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupUser.where(id: group_user_4.id).first).to be_nil

      group_2.add_user(user_1, :owner)
      group_user_5 = GroupUser.last
      api_delete :destroy, user_2_token,
                 parameters: {id: group_user_5.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupUser.where(id: group_user_5.id).first).to be_nil
    end
  end

end
