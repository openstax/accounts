require 'rails_helper'

describe User, type: :model do

  it { should have_many :security_logs }

  it 'requires first and last name once set' do
    user = User.new(first_name: "John", username: 'agent_smith')
    expect(user.save).to be(false)
    expect(user.errors[:last_name]).to include("can't be blank")
    user.last_name = 'Smith'
    expect(user.save).to be(true)

    user.first_name = ''
    expect(user.save).to be(false)
    expect(user.errors[:first_name]).to include("can't be blank")

    user.first_name = 'Joe'
    expect(user.save).to be(true)

    user.last_name = nil
    expect(user.save).to be(false)
    expect(user.errors[:last_name]).to include("can't be blank")
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
      user = FactoryGirl.create :user, title: "Mr.", first_name: "Bob", last_name: "Jones"
      expect(user.full_name).to eq "Mr. Bob Jones"
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
    it 'must be unique (case-insensitive) on creation, if provided' do
      user_1 = FactoryGirl.create :user, username: "MyUs3Rn4M3"

      user_2 = FactoryGirl.create :user, username: nil

      user_3 = FactoryGirl.build :user, username: user_1.username
      expect(user_3).not_to be_valid
      expect(user_3.errors).to include(:username)
      expect(user_3.errors[:username]).to include('has already been taken')

      user_4 = FactoryGirl.build :user, username: user_1.username.upcase
      expect(user_4).not_to be_valid
      expect(user_4.errors).to include(:username)

      user_5 = FactoryGirl.build :user, username: user_1.username.downcase
      expect(user_5).not_to be_valid
      expect(user_5.errors).to include(:username)

      user_6 = FactoryGirl.build :user, username: nil
      expect(user_6).to be_valid
    end

    it 'cannot be updated to match (case-insensitive) an existing username' do
      user_1 = FactoryGirl.create :user, username: "MyUs3Rn4M3"

      user_2 = FactoryGirl.create :user, username: nil

      user_3 = FactoryGirl.create :user
      expect(user_3).to be_valid
      expect(user_3.errors).to be_empty

      user_3.username = user_1.username
      expect(user_3).not_to be_valid
      expect(user_3.errors).to include(:username)

      user_3.username = user_1.username.upcase
      expect(user_3).not_to be_valid
      expect(user_3.errors).to include(:username)

      user_3.username = user_1.username.downcase
      expect(user_3).not_to be_valid
      expect(user_3.errors).to include(:username)

      user_3.username = nil
      expect(user_3).to be_valid
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
    user = FactoryGirl.create :user, first_name: 'User', last_name: 'One'
    expect(user.name).to eq('User One')

    user.title = 'Miss'
    expect(user.name).to eq('Miss User One')

    user.title = 'Dr'
    user.suffix = 'Second'
    expect(user.name).to eq('Dr User One Second')
  end

  it 'returns the first name as casual name' do
    user = FactoryGirl.create :user, first_name: 'Nikola', last_name: 'Tesla'
    expect(user.casual_name).to eq('Nikola')
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
