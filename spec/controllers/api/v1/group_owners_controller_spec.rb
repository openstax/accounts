require "spec_helper"

describe Api::V1::GroupOwnersController, :type => :api, :version => :v1 do

  let!(:group_1) { FactoryGirl.create :group, name: 'Group 1',
                                      members_count: 0, owners_count: 0 }
  let!(:group_2) { FactoryGirl.create :group, name: 'Group 2',
                                      members_count: 0, owners_count: 0 }
  let!(:group_3) { FactoryGirl.create :group, name: 'Group 3',
                                      members_count: 0, owners_count: 0, is_public: true }

  let!(:user_1)       { FactoryGirl.create :user, :terms_agreed }
  let!(:user_2)       { FactoryGirl.create :user, :terms_agreed }

  let!(:group_owner_1) { FactoryGirl.create :group_owner, group: group_2,
                                                          user: user_2 }

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
      expect{api_get :index, nil}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must not list group ownerships for an app without a user token' do
      expect{api_get :index, untrusted_application_token}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
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
      expected_response = [{'user_id' => user_1.id,
        'group' => {
          'id' => group_1.id,
          'name' => 'Group 1',
          'is_public' => false,
          'owners' => [
            {'id' => user_1.id, 'username' => user_1.username}
          ],
          'members' => [],
          'nestings' => [],
          'supertree_group_ids' => [group_1.id],
          'subtree_group_ids' => [group_1.id],
          'subtree_member_ids' => []
      }}]

      expect(JSON.parse(response.body)).to eq(expected_response)

      FactoryGirl.create(:group_nesting, container_group: group_1, member_group: group_2)
      controller.current_human_user.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{'user_id' => user_1.id,
        'group' => {
          'id' => group_1.id,
          'name' => 'Group 1',
          'is_public' => false,
          'owners' => [
            {'id' => user_1.id, 'username' => user_1.username}
          ],
          'members' => [],
          'nestings' => [
            {
              'container_group_id' => group_1.id,
              'member_group_id' => group_2.id,
            }
          ],
          'supertree_group_ids' => [group_1.id],
          'subtree_group_ids' => [group_1.id, group_2.id],
          'subtree_member_ids' => []
      }}]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.add_owner(user_1)
      controller.current_human_user.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{'user_id' => user_1.id,
        'group' => {
          'id' => group_1.id,
          'name' => 'Group 1',
          'is_public' => false,
          'owners' => [
            {'id' => user_1.id, 'username' => user_1.username}
          ],
          'members' => [],
          'nestings' => [
            {
              'container_group_id' => group_1.id,
              'member_group_id' => group_2.id,
            }
          ],
          'supertree_group_ids' => [group_1.id],
          'subtree_group_ids' => [group_1.id, group_2.id],
          'subtree_member_ids' => []
        }},
        {'user_id' => user_1.id,
         'group' => {
           'id' => group_2.id,
           'name' => 'Group 2',
           'is_public' => false,
           'owners' => [
             {'id' => user_1.id, 'username' => user_1.username},
             {'id' => user_2.id, 'username' => user_2.username}
           ],
           'members' => [],
           'nestings' => [],
           'supertree_group_ids' => [group_2.id, group_1.id],
           'subtree_group_ids' => [group_2.id],
           'subtree_member_ids' => []
        }}]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_3.add_owner(user_1)
      controller.current_human_user.reload

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{'user_id' => user_1.id,
        'group' => {
          'id' => group_1.id,
          'name' => 'Group 1',
          'is_public' => false,
          'owners' => [
            {'id' => user_1.id, 'username' => user_1.username}
          ],
          'members' => [],
          'nestings' => [
            {
              'container_group_id' => group_1.id,
              'member_group_id' => group_2.id,
            }
          ],
          'supertree_group_ids' => [group_1.id],
          'subtree_group_ids' => [group_1.id, group_2.id],
          'subtree_member_ids' => []
        }},
        {'user_id' => user_1.id,
         'group' => {
           'id' => group_2.id,
           'name' => 'Group 2',
           'is_public' => false,
           'owners' => [
             {'id' => user_1.id, 'username' => user_1.username},
             {'id' => user_2.id, 'username' => user_2.username}
           ],
           'members' => [],
           'nestings' => [],
           'supertree_group_ids' => [group_2.id, group_1.id],
           'subtree_group_ids' => [group_2.id],
           'subtree_member_ids' => []
        }},
        {'user_id' => user_1.id,
         'group' => {
           'id' => group_3.id,
           'name' => 'Group 3',
           'is_public' => true,
           'owners' => [
             {'id' => user_1.id, 'username' => user_1.username}
           ],
           'members' => [],
           'nestings' => [],
           'supertree_group_ids' => [group_3.id],
           'subtree_group_ids' => [group_3.id],
           'subtree_member_ids' => []
        }}]

      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end

  context 'create' do
    it 'must not create a group_owner without a token' do
      expect{api_post :create, nil, parameters: {group_id: group_3.id,
                                                 user_id: user_2.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must not create a group_owner for an app without a user token' do
      expect{api_post :create, untrusted_application_token,
                      parameters: {group_id: group_3.id,
                                   user_id: user_2.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must not create a group_owner for an unauthorized user' do
      expect{api_post :create, user_1_token, parameters: {group_id: group_3.id,
                                                          user_id: user_2.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty

      group_3.add_member(user_1)
      controller.current_human_user.reload

      expect{api_post :create, user_1_token, parameters: {group_id: group_3.id,
                                                          user_id: user_2.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must create group_owners for authorized users' do
      group_3.add_owner(user_1)
      api_post :create, user_1_token, parameters: {group_id: group_3.id,
                                                   user_id: user_2.id}

      expect(response.code).to eq('201')
      expected_response = {'user_id' => user_2.id,
        'group' => {
          'id' => group_3.id,
          'name' => 'Group 3',
          'is_public' => true,
          'owners' => [
            {'id' => user_1.id, 'username' => user_1.username},
            {'id' => user_2.id, 'username' => user_2.username}
          ],
          'members' => [],
          'nestings' => [],
          'supertree_group_ids' => [group_3.id],
          'subtree_group_ids' => [group_3.id],
          'subtree_member_ids' => []
        }}
      expect(JSON.parse(response.body)).to eq(expected_response)

      group_1.add_owner(user_1)
      api_post :create, user_1_token, parameters: {group_id: group_1.id,
                                                   user_id: user_2.id}

      expect(response.code).to eq('201')
      expected_response = {'user_id' => user_2.id,
        'group' => {
          'id' => group_1.id,
          'name' => 'Group 1',
          'is_public' => false,
          'owners' => [
            {'id' => user_1.id, 'username' => user_1.username},
            {'id' => user_2.id, 'username' => user_2.username}
          ],
          'members' => [],
          'nestings' => [],
          'supertree_group_ids' => [group_1.id],
          'subtree_group_ids' => [group_1.id],
          'subtree_member_ids' => []
        }}
      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end

  context 'destroy' do
    it 'must not destroy a group_owner without a token' do
      expect{api_delete :destroy, nil,
                        parameters: {group_id: group_2.id,
                                     user_id: user_2.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupOwner.where(id: group_owner_1.id).first).not_to be_nil
    end

    it 'must not destroy a group_owner for an app without a user token' do
      expect{api_delete :destroy, untrusted_application_token,
                        parameters: {group_id: group_2.id,
                                     user_id: user_2.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupOwner.where(id: group_owner_1.id).first).not_to be_nil
    end

    it 'must not destroy a group_owner for an unauthorized user' do
      expect{api_delete :destroy, user_1_token,
                        parameters: {group_id: group_2.id,
                                     user_id: user_2.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupOwner.where(id: group_owner_1.id).first).not_to be_nil

      group_2.add_member(user_1)

      expect{api_delete :destroy, user_1_token,
                        parameters: {group_id: group_2.id,
                                     user_id: user_2.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupOwner.where(id: group_owner_1.id).first).not_to be_nil
    end

    it 'must destroy group_owners for authorized users' do
      group_2.add_owner(user_1)
      group_owner_2 = GroupOwner.last
      api_delete :destroy, user_1_token,
                 parameters: {group_id: group_2.id,
                              user_id: user_1.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupOwner.where(id: group_owner_2.id).first).to be_nil

      group_2.add_owner(user_1)
      api_delete :destroy, user_1_token,
                 parameters: {group_id: group_2.id,
                              user_id: user_2.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupOwner.where(id: group_owner_1.id).first).to be_nil
    end
  end

end
