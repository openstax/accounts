require 'rails_helper'

RSpec.describe User, type: :model do

  subject(:user) { FactoryBot.create :user }

  it { is_expected.to have_many :security_logs }

  it { is_expected.to validate_presence_of(:faculty_status) }
  it { is_expected.to validate_presence_of(:role          ) }
  it { is_expected.to validate_presence_of(:school_type   ) }

  it { is_expected.to validate_uniqueness_of(:uuid              ).case_insensitive }
  it { is_expected.to validate_uniqueness_of(:support_identifier).case_insensitive }

  context 'when the user is activated' do
    let(:user) { User.new.tap {|u| u.state = 'activated'} }

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
    user = FactoryBot.create :user, title: " Mr ", first_name: "Bob"
    expect(user.title).to eq "Mr"

    user = FactoryBot.create :user, first_name: " Bob\n"
    expect(user.first_name).to eq "Bob"

    user = FactoryBot.create :user, last_name: " Jo nes "
    expect(user.last_name).to eq "Jo nes"

    user = FactoryBot.create :user, suffix: " Jr. ", first_name: "Bobs"
    expect(user.suffix).to eq "Jr."

    user = FactoryBot.create :user, username: " user "
    expect(user.username).to eq "user"

    user = FactoryBot.create :user, self_reported_school: " Rice University\t "
    expect(user.self_reported_school).to eq "Rice University"
  end

  context 'full_name' do
    it 'puts all the pieces together' do
      user = FactoryBot.create :user, title: "Mr.", first_name: "Bob", last_name: "Jones", suffix: "Sr."
      expect(user.full_name).to eq "Mr. Bob Jones Sr."
    end

    it 'includes the title if present' do
      user = FactoryBot.create :user, title: "Mr.", first_name: "Bob", last_name: "Jones"
      expect(user.full_name).to eq "Mr. Bob Jones"
    end

    it 'populates first/last when set' do
      user = FactoryBot.create :user
      user.full_name = '  Bobby Jones'
      expect(user.first_name).to eq 'Bobby'
      expect(user.last_name).to eq 'Jones'

      user.full_name = 'Bob'
      expect(user.first_name).to eq 'Bob'
      expect(user.last_name).to eq ''

      user.full_name = 'Bob Smith Thomas Esq'
      expect(user.first_name).to eq 'Bob'
      expect(user.last_name).to eq 'Smith Thomas Esq'
    end
  end

  context 'uuid' do
    it 'is generated when created' do
      user = FactoryBot.create :user
      expect(user.uuid.length).to eq(36)
    end

    it 'cannot be updated' do
      user = FactoryBot.create :user
      old_uuid = user.uuid
      user.update_attributes(first_name: 'New')
      expect(user.reload.first_name).to eq('New')
      expect(user.uuid).to eq(old_uuid)

      new_uuid = SecureRandom.uuid
      user.uuid = new_uuid
      user.save
      expect(user.reload.uuid).to eq(old_uuid)
    end
  end

  context 'support_identifier' do
    it 'is generated when created' do
      user = FactoryBot.create :user
      expect(user.support_identifier).to start_with('cs')
      expect(user.support_identifier.length).to eq(11)
    end

    it 'cannot be updated' do
      user = FactoryBot.create :user
      old_identifier = user.support_identifier
      user.update_attributes(first_name: 'New')
      expect(user.reload.first_name).to eq('New')
      expect(user.support_identifier).to eq(old_identifier)

      new_identifier = "cs_#{SecureRandom.hex(4)}"
      user.support_identifier = new_identifier
      user.save
      expect(user.reload.support_identifier).to eq(old_identifier)
    end
  end

  context 'username' do
    it 'must be unique (case-insensitive) on creation, if provided' do
      user_1 = FactoryBot.create :user, username: "MyUs3Rn4M3"

      user_2 = FactoryBot.create :user, username: nil

      user_3 = FactoryBot.build :user, username: user_1.username
      expect(user_3).not_to be_valid
      expect(user_3.errors).to include(:username)
      expect(user_3).to have_error(:username, :taken)

      user_4 = FactoryBot.build :user, username: user_1.username.upcase
      expect(user_4).not_to be_valid
      expect(user_4.errors).to include(:username)

      user_5 = FactoryBot.build :user, username: user_1.username.downcase
      expect(user_5).not_to be_valid
      expect(user_5.errors).to include(:username)

      user_6 = FactoryBot.build :user, username: nil
      expect(user_6).to be_valid
    end

    it 'cannot be updated to match (case-insensitive) an existing username' do
      user_1 = FactoryBot.create :user, username: "MyUs3Rn4M3"

      user_2 = FactoryBot.create :user, username: nil

      user_3 = FactoryBot.create :user
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
      user_1 = FactoryBot.create :user, username: "MyUs3Rn4M3"
      user_2 = FactoryBot.create :user
      user_2.update_column :username, user_1.username.upcase
      expect(user_2.reload).to be_valid
      expect(user_2.errors).to be_empty

      user_2.first_name = SecureRandom.hex(3)
      user_2.save!

      user_3 = FactoryBot.create :user
      user_3.update_column :username, user_1.username.downcase
      expect(user_3.reload).to be_valid
      expect(user_3.errors).to be_empty

      user_3.first_name = SecureRandom.hex(3)
      user_3.save!
    end
  end

  it 'returns a name' do
    user = FactoryBot.create :user, first_name: 'User', last_name: 'One'
    expect(user.name).to eq('User One')

    user.title = 'Miss'
    expect(user.name).to eq('Miss User One')

    user.title = 'Dr'
    user.suffix = 'Second'
    expect(user.name).to eq('Dr User One Second')
  end

  it 'returns the first name as casual name' do
    user = FactoryBot.create :user, first_name: 'Nikola', last_name: 'Tesla'
    expect(user.casual_name).to eq('Nikola')
  end


  context "state" do
    it "defaults to needs_profile" do
      expect(User.new.state ).to eq("needs_profile")
      expect(User.new.is_needs_profile? ).to be_truthy
    end

    it "can be set to active" do
      user = FactoryBot.create(:user)
      user.state = 'activated'
      expect(user.save).to be_truthy
      expect(user.reload.is_temp?).to be_falsey
    end

    it "relays it's value to helper methods" do
      user = FactoryBot.create(:user)
      user.state = 'temp'
      expect(user.is_temp?).to    be_truthy
      expect(user.is_activated?).to be_falsey
      user.state = 'activated'
      expect(user.is_activated?).to be_truthy
      expect(user.is_temp?).to    be_falsey
    end

    it "disallows invalid values" do
      user = FactoryBot.create(:user)
      user.state = 'a-crazy-invalid-value'
      expect(user.save).to be_falsey
      expect(user.errors[:state]).not_to be_empty
    end
  end

  context "login_token" do
    let(:user) { FactoryBot.create :user }

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

      user2 = FactoryBot.create :user
      expect{
        user2.update_attribute(:login_token, user.login_token)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context '#guessed_preferred_confirmed_email' do
    let(:user) { FactoryBot.create :user }

    before(:each) do
      Timecop.freeze(3.minutes.ago)  {
        @email_a = AddEmailToUser['a@a.com', user]
      }
      Timecop.freeze(0.minutes.ago)  { AddEmailToUser['b@b.com', user, already_verified: true] }
      Timecop.freeze(-1.minutes.ago) { @email_c = AddEmailToUser['c@c.com', user] }
      Timecop.freeze(-3.minutes.ago) { AddEmailToUser['d@d.com', user, already_verified: true] }
    end

    context 'with no manually entered emails' do
      context 'with the user\'s email_addresses and contact_infos not yet loaded' do
        before do
          user.email_addresses.reset
          user.contact_infos.reset
        end

        it 'chooses earliest auto confirmed email' do
          expect(user.guessed_preferred_confirmed_email).to eq 'b@b.com'
        end
      end

      context 'with the user\'s contact_infos already loaded' do
        before do
          user.email_addresses.reset
          user.contact_infos.reload
        end

        it 'chooses earliest auto confirmed email' do
          expect(user.guessed_preferred_confirmed_email).to eq 'b@b.com'
        end
      end

      context 'with the user\'s email_addresses and contact_infos already loaded' do
        before do
          user.email_addresses.reload
          user.contact_infos.reload
        end

        it 'chooses earliest auto confirmed email' do
          expect(user.guessed_preferred_confirmed_email).to eq 'b@b.com'
        end
      end
    end

    context 'with some manually entered emails' do
      before do
        ConfirmContactInfo[@email_a]
        ConfirmContactInfo[@email_c]
      end

      context 'with the user\'s email_addresses and contact_infos not yet loaded' do
        before do
          user.email_addresses.reset
          user.contact_infos.reset
        end

        it 'chooses latest manually entered email' do
          expect(user.guessed_preferred_confirmed_email).to eq 'c@c.com'
        end
      end

      context 'with the user\'s contact_infos already loaded' do
        before do
          user.email_addresses.reset
          user.contact_infos.reload
        end

        it 'chooses latest manually entered email' do
          expect(user.guessed_preferred_confirmed_email).to eq 'c@c.com'
        end
      end

      context 'with the user\'s email_addresses and contact_infos already loaded' do
        before do
          user.email_addresses.reload
          user.contact_infos.reload
        end

        it 'chooses latest manually entered email' do
          expect(user.guessed_preferred_confirmed_email).to eq 'c@c.com'
        end
      end
    end
  end
end
