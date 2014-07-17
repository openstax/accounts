require "spec_helper"

describe Api::V1::GroupsController, :type => :api, :version => :v1 do

  let!(:group_1) { FactoryGirl.create :group, name: 'Group 1', users_count: 0 }
  let!(:group_2) { FactoryGirl.create :group, name: 'Group 2', users_count: 0 }
  let!(:group_3) { FactoryGirl.create :group, name: 'Group 3', users_count: 0,
                                              visibility: 'public' }

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
        'visibility' => 'public',
        'group_users' => [],
        'group_sharings' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_1.add_user(user_1)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'visibility' => 'private',
        'group_users' => [
          {'user_id' => user_1.id}
        ],
        'group_sharings' => []
      },
      {
        'name' => 'Group 3',
        'visibility' => 'public',
        'group_users' => [],
        'group_sharings' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.share_with(user_1)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'visibility' => 'private',
        'group_users' => [
          {'user_id' => user_1.id}
        ],
        'group_sharings' => []
      },
      {
        'name' => 'Group 2',
        'visibility' => 'private',
        'group_users' => [],
        'group_sharings' => [
          {'shared_with_id' => user_1.id, 'shared_with_type' => 'User'}
        ]
      },
      {
        'name' => 'Group 3',
        'visibility' => 'public',
        'group_users' => [],
        'group_sharings' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.group_sharings.first.destroy

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'visibility' => 'private',
        'group_users' => [
          {'user_id' => user_1.id}
        ],
        'group_sharings' => []
      },
      {
        'name' => 'Group 3',
        'visibility' => 'public',
        'group_users' => [],
        'group_sharings' => []
      }]

      group_2.share_with(group_1)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'visibility' => 'private',
        'group_users' => [
          {'user_id' => user_1.id}
        ],
        'group_sharings' => []
      },
      {
        'name' => 'Group 2',
        'visibility' => 'private',
        'group_users' => [],
        'group_sharings' => [
          {'shared_with_id' => group_1.id, 'shared_with_type' => 'Group'}
        ]
      },
      {
        'name' => 'Group 3',
        'visibility' => 'public',
        'group_users' => [],
        'group_sharings' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)

      group_2.add_user(user_2)

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expected_response = [{
        'name' => 'Group 1',
        'visibility' => 'private',
        'group_users' => [
          {'user_id' => user_1.id}
        ],
        'group_sharings' => []
      },
      {
        'name' => 'Group 2',
        'visibility' => 'private',
        'group_users' => [
          {'user_id' => user_2.id}
        ],
        'group_sharings' => [
          {'shared_with_id' => group_1.id, 'shared_with_type' => 'Group'}
        ]
      },
      {
        'name' => 'Group 3',
        'visibility' => 'public',
        'group_users' => [],
        'group_sharings' => []
      }]

      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end

  context 'show' do
  end

  context 'create' do
  end

  context 'update' do
  end

  context 'destroy' do
  end

end