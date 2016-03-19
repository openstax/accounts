require 'rails_helper'

describe User do

  it 'requires at least a first or last name if a title is set' do
    user = User.new(title: "Hi")
    expect(user).not_to be_valid

    user = User.new(suffix: "Hi")
    expect(user).not_to be_valid
  end

  it 'strips whitespace off of title, first & last names, suffix, username' do
    user = FactoryGirl.create :user, title: " Mr ", first_name: "Bob"
    expect(user.title).to eq "Mr"

    user = FactoryGirl.create :user, first_name: " Bob\n"
    expect(user.first_name).to eq "Bob"

    user = FactoryGirl.create :user, last_name: " Jo nes "
    expect(user.last_name).to eq "Jo nes"

    user = FactoryGirl.create :user, suffix: " Jr. ", first_name: "Bobs"
    expect(user.suffix).to eq "Jr."

    user = FactoryGirl.create :user, username: " user "
    expect(user.username).to eq "user"
  end

  context 'full_name' do
    it 'puts all the pieces together' do
      user = FactoryGirl.create :user, title: "Mr.", first_name: "Bob", last_name: "Jones", suffix: "Sr."
      expect(user.full_name).to eq "Mr. Bob Jones Sr."
    end

    it 'includes the title if present' do
      user = FactoryGirl.create :user, title: "Mr.", first_name: "Bob"
      expect(user.full_name).to eq "Mr. Bob"
    end

    it 'includes the suffix if present' do
      user = FactoryGirl.create :user, suffix: "Jr.", first_name: "Bob"
      expect(user.full_name).to eq "Bob Jr."
    end

    it 'does not have extra spaces in middle if missing first name' do
      user = FactoryGirl.create :user, title: "Professor", last_name: "Einstein"
      expect(user.full_name).to eq "Professor Einstein"
    end
  end

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

      user_2.first_name = SecureRandom.hex(3)
      user_2.save!

      user_3 = FactoryGirl.build :user, username: user_1.username.downcase
      user_3.save!(validate: false)
      expect(user_3).to be_valid
      expect(user_3.errors).to be_empty

      user_3.first_name = SecureRandom.hex(3)
      user_3.save!
    end
  end

  it 'returns a name' do
    user = FactoryGirl.create :user, username: 'username'
    expect(user.name).to eq('username')

    user.first_name = 'User'
    expect(user.name).to eq('User')

    user.last_name = 'One'
    expect(user.name).to eq('User One')

    user.title = 'Miss'
    expect(user.name).to eq('Miss User One')

    user.title = 'Dr'
    user.suffix = 'Second'
    expect(user.name).to eq('Dr User One Second')
  end

  it 'returns a casual name' do
    user = FactoryGirl.create :user, username: 'username', first_name: ''
    expect(user.casual_name).to eq('username')

    user.first_name = 'First'
    user.last_name = 'Last'
    expect(user.casual_name).to eq('First')
  end


  context "state" do
    it "defaults to temp" do
      expect(User.new.state ).to eq("temp")
      expect(User.new.is_temp? ).to be_truthy
    end

    it "can be set to active" do
      user = FactoryGirl.create(:user)
      user.state = 'activated'
      expect(user.save).to be_truthy
      expect(user.reload.is_temp?).to be_falsey
    end

    it "relays it's value to helper methods" do
      user = FactoryGirl.create(:user)
      user.state = 'temp'
      expect(user.is_temp?).to    be_truthy
      expect(user.is_activated?).to be_falsey
      user.state = 'activated'
      expect(user.is_activated?).to be_truthy
      expect(user.is_temp?).to    be_falsey
    end

    it "disallows invalid values" do
      user = FactoryGirl.create(:user)
      user.state = 'a-crazy-invalid-value'
      expect(user.save).to be_falsey
      expect(user.errors[:state]).not_to be_empty
    end
  end
end
