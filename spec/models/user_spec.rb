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

  context 'username' do
    it 'must be unique (case-insensitive) on creation' do
      user_1 = FactoryGirl.create :user, username: "MyUs3Rn4M3"

      user_2 = FactoryGirl.build :user, username: user_1.username
      expect(user_2).not_to be_valid
      expect(user_2.errors).to include(:username)
      expect(user_2.errors[:username]).to include('has already been taken')

      user_3 = FactoryGirl.build :user, username: user_1.username.upcase
      expect(user_3).not_to be_valid
      expect(user_3.errors).to include(:username)

      user_4 = FactoryGirl.build :user, username: user_1.username.downcase
      expect(user_4).not_to be_valid
      expect(user_4.errors).to include(:username)
    end

    it 'cannot be updated to match (case-insensitive) an existing username' do
      user_1 = FactoryGirl.create :user, username: "MyUs3Rn4M3"

      user_2 = FactoryGirl.create :user
      expect(user_2).to be_valid
      expect(user_2.errors).to be_empty

      user_2.username = user_1.username
      expect(user_2).not_to be_valid
      expect(user_2.errors).to include(:username)

      user_2.username = user_1.username.upcase
      expect(user_2).not_to be_valid
      expect(user_2.errors).to include(:username)

      user_2.username = user_1.username.downcase
      expect(user_2).not_to be_valid
      expect(user_2.errors).to include(:username)
    end

    it 'does not interfere with updates if duplicated but not changed' do
      user_1 = FactoryGirl.create :user, username: "MyUs3Rn4M3"

      user_2 = FactoryGirl.build :user, username: user_1.username.upcase
      user_2.save!(validate: false)
      expect(user_2).to be_valid
      expect(user_2.errors).to be_empty

      user_2.full_name = SecureRandom.hex(3)
      user_2.save!

      user_3 = FactoryGirl.build :user, username: user_1.username.downcase
      user_3.save!(validate: false)
      expect(user_3).to be_valid
      expect(user_3.errors).to be_empty

      user_3.full_name = SecureRandom.hex(3)
      user_3.save!
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

    user.title = 'Dr'
    user.full_name = ''
    user.suffix = 'Second'
    expect(user.name).to eq('Dr User One Second')
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
