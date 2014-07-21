require "spec_helper"

describe Api::V1::GroupGroupsController, :type => :api, :version => :v1 do

  let!(:group_1) { FactoryGirl.create :group, name: 'Group 1', users_count: 0 }
  let!(:group_2) { FactoryGirl.create :group, name: 'Group 2', users_count: 0 }
  let!(:group_3) { FactoryGirl.create :group, name: 'Group 3', users_count: 0,
                                              is_public: true }

  let!(:user_1)       { FactoryGirl.create :user, :terms_agreed }
  let!(:user_2)       { FactoryGirl.create :user, :terms_agreed }

  let!(:group_group_1) { FactoryGirl.create :group_group, permitter_group: group_2,
                                            permitted_group: group_3, role: 'manager' }

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

  before(:each) do
    group_1.add_user(user_1)
    group_3.add_user(user_2)
  end

  context 'create' do
    it 'must not create a group_group without a token' do
      expect{api_post :create, nil, parameters: {group_id: group_3.id},
                      raw_post_data: {permitted_group_id: group_2.id, role: :viewer}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must not create a group_group for an app without a user token' do
      expect{api_post :create, untrusted_application_token,
                      parameters: {group_id: group_3.id},
                      raw_post_data: {permitted_group_id: group_2.id, role: :viewer}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must not create a group_group for an unauthorized user' do
      expect{api_post :create, user_1_token, parameters: {group_id: group_3.id},
                      raw_post_data: {permitted_group_id: group_2.id, role: :viewer}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty

      group_3.add_permitted_group(group_1)
      controller.current_human_user.reload

      expect{api_post :create, user_1_token, parameters: {group_id: group_3.id},
                      raw_post_data: {permitted_group_id: group_2.id, role: :viewer}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty

      group_3.add_permitted_group(group_1, :viewer)
      controller.current_human_user.reload

      expect{api_post :create, user_1_token, parameters: {group_id: group_3.id},
                      raw_post_data: {permitted_group_id: group_2.id, role: :viewer}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
    end

    it 'must create group_groups for authorized users' do
      group_3.add_permitted_group(group_1, :manager)
      api_post :create, user_1_token, parameters: {group_id: group_3.id},
               raw_post_data: {permitted_group_id: group_2.id, role: :viewer}

      expect(response.code).to eq('201')
      expected_response = {'permitter_group' => {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => {'users' => [
          {'id' => user_2.id, 'username' => user_2.username}
        ]},
        'owners' => {'users' => [], 'groups' => []},
        'managers' => {'users' => [], 'groups' => [
          {'name' => 'Group 1', 'users' => [
            {'id' => user_1.id, 'username' => user_1.username}
          ]}
        ]},
        'viewers' => {'users' => [], 'groups' => [
          {'name' => 'Group 2', 'users' => []}
        ]}
      }, 'permitted_group_id' => group_2.id, 'role' => 'viewer'}
      expect(JSON.parse(response.body)).to eq(expected_response)

      group_1.add_permitted_group(group_1, :owner)
      api_post :create, user_1_token, parameters: {group_id: group_1.id},
               raw_post_data: {permitted_group_id: group_2.id, role: :manager}

      expect(response.code).to eq('201')
      expected_response = {'permitter_group' => {
        'name' => 'Group 1',
        'is_public' => false,
        'members' => {'users' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]},
        'owners' => {'users' => [], 'groups' => [
          {'name' => 'Group 1', 'users' => [
            {'id' => user_1.id, 'username' => user_1.username}
          ]}
        ]},
        'managers' => {'users' => [], 'groups' => [
          {'name' => 'Group 2', 'users' => []}
        ]},
        'viewers' => {'users' => [], 'groups' => []}
      }, 'permitted_group_id' => group_2.id, 'role' => 'manager'}
      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end

  context 'destroy' do
    it 'must not destroy a group_group without a token' do
      expect{api_delete :destroy, nil,
                        parameters: {id: group_group_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupGroup.where(id: group_group_1.id).first).not_to be_nil
    end

    it 'must not destroy a group for an app without a user token' do
      expect{api_delete :destroy, untrusted_application_token,
                        parameters: {id: group_group_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupGroup.where(id: group_group_1.id).first).not_to be_nil
    end

    it 'must not destroy a group for an unauthorized user' do
      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_group_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupGroup.where(id: group_group_1.id).first).not_to be_nil

      group_2.add_permitted_group(group_1)

      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_group_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupGroup.where(id: group_group_1.id).first).not_to be_nil

      group_2.add_permitted_group(group_1, :viewer)

      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_group_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupGroup.where(id: group_group_1.id).first).not_to be_nil

      group_2.add_permitted_group(group_1, :manager)

      expect{api_delete :destroy, user_1_token,
                        parameters: {id: group_group_1.id}}.to(
        raise_error(SecurityTransgression))

      expect(response.body).to be_empty
      expect(GroupGroup.where(id: group_group_1.id).first).not_to be_nil
    end

    it 'must destroy group_groups for authorized users' do
      group_2.add_permitted_group(group_1)
      group_group_2 = GroupGroup.last
      api_delete :destroy, user_2_token,
                 parameters: {id: group_group_2.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupGroup.where(id: group_group_2.id).first).to be_nil

      group_2.add_permitted_group(group_1, :viewer)
      group_group_3 = GroupGroup.last
      api_delete :destroy, user_2_token,
                 parameters: {id: group_group_3.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupGroup.where(id: group_group_3.id).first).to be_nil

      group_2.add_permitted_group(group_3, :owner)
      group_2.add_permitted_group(group_1, :manager)
      group_group_4 = GroupGroup.last
      api_delete :destroy, user_2_token,
                 parameters: {id: group_group_4.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupGroup.where(id: group_group_4.id).first).to be_nil

      group_2.add_permitted_group(group_1, :owner)
      group_group_5 = GroupGroup.last
      api_delete :destroy, user_2_token,
                 parameters: {id: group_group_5.id}

      expect(response.code).to eq('204')
      expect(response.body).to be_blank
      expect(GroupGroup.where(id: group_group_5.id).first).to be_nil
    end
  end

end
