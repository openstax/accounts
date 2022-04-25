require 'rails_helper'

RSpec.describe User, type: :model do

  subject(:user) { FactoryBot.create :user }

  it { is_expected.to have_many :security_logs }

  it { is_expected.to validate_presence_of(:faculty_status) }
  it { is_expected.to validate_presence_of(:role) }
  it { is_expected.to validate_presence_of(:school_type) }

  it { is_expected.to validate_uniqueness_of(:uuid).case_insensitive }

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
        user.update(first_name: "John", last_name: "Smith")
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

  it 'removes certain unallowed special characters from first and last name' do
    user = FactoryBot.create :user, last_name: "D'Amore"
    expect(user.last_name).to eq "D'Amore"

    user = FactoryBot.create :user, first_name: "Mary-Ann"
    expect(user.first_name).to eq "Mary-Ann"
  end

  it 'allows accented and non-english characters in first and last name' do
    user = FactoryBot.create :user, last_name: "Maève"
    expect(user.last_name).to eq "Maève"

    user = FactoryBot.create :user, first_name: "Brièle"
    expect(user.first_name).to eq "Brièle"

    user = FactoryBot.create :user, first_name: "Адам"
    expect(user.first_name).to eq "Адам"

    user = FactoryBot.create :user, last_name: "Екатерина"
    expect(user.last_name).to eq "Екатерина"
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
      user.update(first_name: 'New')
      expect(user.reload.first_name).to eq('New')
      expect(user.uuid).to eq(old_uuid)

      new_uuid = SecureRandom.uuid
      user.uuid = new_uuid
      user.save
      expect(user.reload.uuid).to eq(old_uuid)
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
      user_2.update_column :username, user_1.username.upcase # rubocop:disable Rails/SkipsModelValidations
      expect(user_2.reload).to be_valid
      expect(user_2.errors).to be_empty

      user_2.first_name = SecureRandom.hex(3)
      user_2.save!

      user_3 = FactoryBot.create :user
      user_3.update_column :username, user_1.username.downcase # rubocop:disable Rails/SkipsModelValidations
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


  context "state" do
    it "defaults to unverified" do
      expect(User.new.state ).to eq("unverified")
      expect(User.new.unverified? ).to be_truthy
    end

    it "can be set to active" do
      user = FactoryBot.create(:user)
      user.state = 'activated'
      expect(user.save).to be_truthy
      expect(user.reload.temporary?).to be_falsey
    end

    it "relays it's value to helper methods" do
      user = FactoryBot.create(:user)
      user.state = User::TEMP
      expect(user.temporary?).to    be_truthy
      expect(user.activated?).to be_falsey
      user.state = User::ACTIVATED
      expect(user.activated?).to be_truthy
      expect(user.temporary?).to    be_falsey
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
      expect(user.login_token_expires_at).to be > Time.zone.now

      expect(user.save).to be_truthy
      Timecop.freeze(9.minutes.from_now) do
        expect(user.login_token_expired?).to be_falsey
      end
      Timecop.freeze(11.minutes.from_now) do
        expect(user.login_token_expired?).to be_truthy
      end
    end

    it 'cannot be used twice' do
      user.refresh_login_token
      user.save

      user2 = FactoryBot.create :user
      expect{
        user2.update(login_token: user.login_token)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context '#guessed_preferred_confirmed_email' do
    let(:user) { FactoryBot.create :user }

    before(:each) do
      Timecop.freeze(3.minutes.ago)  {
        @email_a = CreateEmailForUser['a@a.com', user]
      }
      Timecop.freeze(0.minutes.ago)  { CreateEmailForUser['b@b.com', user, already_verified: true] }
      Timecop.freeze(-1.minute.ago) { @email_c = CreateEmailForUser['c@c.com', user] }
      Timecop.freeze(-3.minutes.ago) { CreateEmailForUser['d@d.com', user, already_verified: true] }
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

  describe '.cleanup_unverified_users' do
    before do
      FactoryBot.create(:user, created_at: 10.years.ago, state: User::ACTIVATED)
      @older_unverified_user = FactoryBot.create(:user, created_at: 10.years.ago, state: User::UNVERIFIED)
      FactoryBot.create(:user, created_at: 1.month.ago, state: User::ACTIVATED)
      FactoryBot.create(:user, created_at: 1.month.ago, state: User::UNVERIFIED)
    end

    it 'removes the unverified users older than a year' do
      expect(User.count).to eq 4
      described_class.cleanup_unverified_users
      expect(User.count).to eq 3
      expect(User.find_by(id: @older_unverified_user.id)).to be_nil
    end
  end

  describe '#sheerid_supported?' do
    context 'is sheer supported' do
      subject(:user) do
        FactoryBot.create(:user, country_code: '1')
      end

      it 'returns sheer supported' do
        expect(user.sheerid_supported?).to be_truthy
      end
    end

    context 'is not sheer supported' do
      subject(:user) do
        FactoryBot.create(:user, country_code: '111')
      end

      it 'returns not sheer supported' do
        expect(user.sheerid_supported?).to be_falsey
      end
    end

    context 'country code not set' do
      subject(:user) do
        FactoryBot.create(:user, country_code: nil)
      end

      it 'returns not sheer supported' do
        expect(user.sheerid_supported?).to be_falsey
      end
    end
  end

  describe '#best_email_address_for_salesforce' do
    let(:school_issued_email) { FactoryBot.create(:email_address, is_school_issued: true, verified: false) }
    let(:verified_email) { FactoryBot.create(:email_address, is_school_issued: false, verified: true) }
    let(:unverified_email) { FactoryBot.create(:email_address, is_school_issued: false, verified: false) }

    context 'when user has a school-issued email (not verified), a verified email, and an unverified email' do
      subject(:user) {
        user = FactoryBot.create(:user)
        user.email_addresses << school_issued_email
        user.email_addresses << verified_email
        user.email_addresses << unverified_email
        user.save!
        user
      }

      it 'returns the school-issued email' do
        expect(user.best_email_address_for_salesforce).to eq(school_issued_email.value)
      end
    end

    context 'when user has a verified email, and an unverified email' do
      subject(:user) {
        user = FactoryBot.create(:user)
        user.email_addresses << verified_email
        user.email_addresses << unverified_email
        user.save!
        user
      }

      it 'returns the verified email' do
        expect(user.best_email_address_for_salesforce).to eq(verified_email.value)
      end
    end

    context 'when user has only an unverified email' do
      subject(:user) {
        user = FactoryBot.create(:user)
        user.email_addresses << unverified_email
        user.save!
        user
      }

      it 'returns the unverified email' do
        expect(user.best_email_address_for_salesforce).to eq(unverified_email.value)
      end
    end
  end

  describe '#is_tutor_user?' do
    context 'when the app name includes tutor in the name' do
      subject(:user) do
        FactoryBot.create(:user, source_application: tutor_app)
      end

      let(:tutor_app) do
        FactoryBot.create(:doorkeeper_application, name: '123 Tutor Dev')
      end

      it 'returns true' do
        expect(user.is_tutor_user?).to be_truthy
      end
    end

    context 'when the app name does not include tutor in the name' do
      subject(:user) do
        FactoryBot.create(:user, source_application: tutor_app)
      end

      let(:tutor_app) do
        FactoryBot.create(:doorkeeper_application, name: '123 CMS Dev')
      end

      it 'returns false' do
        expect(user.is_tutor_user?).to be_falsey
      end
    end

    context 'country code not set' do
      subject(:user) do
        FactoryBot.create(:user, country_code: nil)
      end

      it 'returns not sheer supported' do
        expect(user.sheerid_supported?).to be_falsey
      end
    end
  end

end
