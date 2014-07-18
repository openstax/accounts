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
        'members' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_1.add_user(user_1)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.add_permitted_group(group_1)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]
      },
      {
        'name' => 'Group 2',
        'is_public' => false,
        'members' => []
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.permitted_group_groups.first.destroy

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => []
      }]

      group_3.add_user(user_2)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'is_public' => false,
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]
      },
      {
        'name' => 'Group 3',
        'is_public' => true,
        'members' => [
          {'id' => user_2.id, 'username' => user_2.username}
        ]
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
        'members' => []
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
        'members' => [
          {'id' => user_1.id, 'username' => user_1.username}
        ]
      }
      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.add_permitted_group(group_1)
      api_get :show, user_1_token, parameters: {id: group_2.id}

      expect(response.code).to eq('200')
      expected_response = {
        'name' => 'Group 2',
        'is_public' => false,
        'members' => []
      }
      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end

  context 'create' do
  end

  context 'update' do
  end

  context 'destroy' do
  end

end