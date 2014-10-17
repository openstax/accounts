require 'spec_helper'

describe User do

  context 'uuid' do
    it 'is generated when created' do
      user = FactoryGirl.create :user
      expect(user.uuid.length).to eq(36)
    end

    it 'cannot be updated' do
      user = FactoryGirl.create :user
      old_uuid = user.uuid
      user.update_attributes(first_name: 'New')
      user.reload
      expect(user.first_name).to eq('New')
      expect(user.uuid).to eq(old_uuid)

      new_uuid = SecureRandom.uuid
      user.uuid = new_uuid
      user.save
      user.reload
      expect(user.uuid).to eq(old_uuid)
    end
  end

  it 'returns a name' do
    user = FactoryGirl.create :user, username: 'username', full_name: ''
    expect(user.name).to eq('username')

    user.first_name = 'User'
    expect(user.name).to eq('username')

    user.last_name = 'One'
    expect(user.name).to eq('User One')

    user.full_name = 'User Fullname'
    expect(user.name).to eq('User Fullname')

    user.title = 'Miss'
    expect(user.name).to eq('Miss User Fullname')
  end

  it 'returns a casual name' do
    user = FactoryGirl.create :user, username: 'username', first_name: ''
    expect(user.casual_name).to eq('username')

    user.first_name = 'First'
    user.last_name = 'Last'
    user.full_name = 'Full Name'
    expect(user.casual_name).to eq('First')
  end

end
