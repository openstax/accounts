require 'rails_helper'

describe User, type: :model do

  it { should have_many :security_logs }

  context 'when the user is activated' do
    let(:user) { User.new.tap{|u| u.state = 'activated'} }

    context 'when the names start nil' do
      it 'is valid for the first name to stay blank' do
        user.last_name = "Smith"
        expect(user).to be_valid
      end

      it 'is valid for the last name name to stay blank' do
        user.first_name = "John"
        expect(user).to be_valid
      end
    end

    context 'when the names start populated' do
      before(:each) {
        user.update_attributes(first_name: "John", last_name: "Smith")
      }

      it 'is invalid for the first name to become blank' do
        user.first_name = "   "
        expect(user).not_to be_valid
        expect(user).to have_error(:first_name, :blank)
      end

      it 'is invalid for the last name to become blank' do
        user.last_name = "\t   "
        expect(user).not_to be_valid
        expect(user).to have_error(:last_name, :blank)
      end
    end
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

    user = FactoryGirl.create :user, self_reported_school: " Rice University\t "
    expect(user.self_reported_school).to eq "Rice University"
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
      expect(user_3).to have_error(:username, :taken)

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

  context "#casual_name" do
    it 'returns the first name when present' do
      user = FactoryGirl.create :user, first_name: 'Nikola', last_name: 'Tesla'
      expect(user.casual_name).to eq('Nikola')
    end

    it 'returns the username if no first_name' do
      user = FactoryGirl.create :user, username: 'bob', first_name: ''
      expect(user.casual_name).to eq('bob')
    end

    it 'returns last name if first and username not present' do
      user = FactoryGirl.create :user, username: '', first_name: '', last_name: 'Last'
      expect(user.last_name).to eq 'Last'
    end
  end

  context "#formal_name" do
    it "returns nil for missing title (can't be formal without title)" do
      user = FactoryGirl.create :user, title: '', first_name: "Bob", last_name: "Smith", suffix: "Sr."
      expect(user.formal_name).to be_nil
    end

    it "returns if title and lastname present" do
      user = FactoryGirl.create :user, title: 'Dr.  ', first_name: "", last_name: "Smith ", suffix: ""
      expect(user.formal_name).to eq "Dr. Smith"
    end
  end

  context "#standard_name" do
    it "gives the formal name if present" do
      user = FactoryGirl.create :user, title: 'Dr.  ', first_name: "", last_name: "Smith ", suffix: ""
      expect(user.standard_name).to eq "Dr. Smith"
    end

    it "gives the casual name if no formal name" do
      user = FactoryGirl.create :user, title: '', first_name: "Yikes ", last_name: "Smith ", suffix: ""
      expect(user.standard_name).to eq "Yikes"
    end
  end

  context "state" do
    it "defaults to needs_profile" do
      expect(User.new.state ).to eq("needs_profile")
      expect(User.new.is_needs_profile? ).to be_truthy
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

  context "login_token" do
    let(:user) { FactoryGirl.create :user }

    it 'starts nil' do
      expect(user.login_token).to be_nil
      expect(user.login_token_expired?).to be_falsey
    end

    it 'can be reset without expiring' do
      user.refresh_login_token
      expect(user.login_token).not_to be_nil
      expect(user.login_token_expired?).to be_falsey
      expect(user.save).to be_truthy
    end

    it 'can be reset with an expiration' do
      user.refresh_login_token(expiration_period: 10.minutes)
      expect(user.login_token_expires_at).to be > Time.now

      expect(user.save).to be_truthy
      Timecop.freeze(Time.now + 9.minutes) do
        expect(user.login_token_expired?).to be_falsey
      end
      Timecop.freeze(Time.now + 11.minutes) do
        expect(user.login_token_expired?).to be_truthy
      end
    end

    it 'cannot be used twice' do
      user.refresh_login_token
      user.save

      user2 = FactoryGirl.create :user
      expect{
        user2.update_attribute(:login_token, user.login_token)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context '#guessed_preferred_confirmed_email' do
    let(:user) { FactoryGirl.create :user }

    before(:each) {
      Timecop.freeze(3.minutes.ago)  {
        @email_a = AddEmailToUser['a@a.com', user]
      }
      Timecop.freeze(0.minutes.ago)  { AddEmailToUser['b@b.com', user, already_verified: true] }
      Timecop.freeze(-1.minutes.ago) { @email_c = AddEmailToUser['c@c.com', user] }
      Timecop.freeze(-3.minutes.ago) { AddEmailToUser['d@d.com', user, already_verified: true] }
    }

    it 'chooses latest manually entered emails' do
      ConfirmContactInfo[@email_a]
      ConfirmContactInfo[@email_c]
      expect(user.guessed_preferred_confirmed_email).to eq 'c@c.com'
    end

    it 'chooses earliest auto confirmed if no manually entered emails' do
      expect(user.guessed_preferred_confirmed_email).to eq 'b@b.com'
    end
  end
end
