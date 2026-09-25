require 'rails_helper'

describe UpdateUserContactInfo, type: :routine do
  include ActiveSupport::Testing::TimeHelpers

  let!(:school) { FactoryBot.create :school, salesforce_id: 'SF_SCHOOL_001' }

  describe 'faculty status preservation logic' do
    before { stub_sentry }
    context 'when user has confirmed_faculty status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :confirmed_faculty, uuid: 'test-uuid-001' }

      it 'does not downgrade to pending_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'does not downgrade to incomplete_signup' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'incomplete_signup')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'does not downgrade to no_faculty_info' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'no_faculty_info')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'does not downgrade when faculty_verified is nil' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: nil)
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to rejected_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'rejected_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('rejected_faculty')
      end

      it 'allows update to rejected_by_sheerid' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'rejected_by_sheerid')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('rejected_by_sheerid')
      end

      it 'preserves confirmed_faculty when already confirmed in Salesforce' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end
    end

    context 'when user has pending_faculty status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :pending_faculty, uuid: 'test-uuid-002' }

      it 'does not downgrade to incomplete_signup' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'incomplete_signup')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end

      it 'does not downgrade to no_faculty_info' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'no_faculty_info')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end

      it 'does not downgrade when faculty_verified is nil' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: nil)
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end

      it 'allows upgrade to confirmed_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to rejected_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'rejected_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('rejected_faculty')
      end

      it 'allows update to rejected_by_sheerid' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'rejected_by_sheerid')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('rejected_by_sheerid')
      end
    end

    context 'when user has rejected_faculty status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :rejected_faculty, uuid: 'test-uuid-003' }

      it 'allows update to confirmed_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to pending_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end

      it 'does not downgrade to incomplete_signup' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'incomplete_signup')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('rejected_faculty')
      end

      it 'does not downgrade to no_faculty_info' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'no_faculty_info')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('rejected_faculty')
      end

      it 'does not downgrade when faculty_verified is nil' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: nil)
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('rejected_faculty')
      end
    end

    context 'when user has rejected_by_sheerid status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :rejected_by_sheerid, uuid: 'test-uuid-004' }

      it 'allows update to confirmed_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to pending_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end
    end

    context 'when user has incomplete_signup status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :incomplete_signup, uuid: 'test-uuid-005' }

      it 'allows update to confirmed_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to pending_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end

      it 'allows update to no_faculty_info' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'no_faculty_info')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('no_faculty_info')
      end
    end

    context 'when user has no_faculty_info status' do
      let!(:user) { FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'test-uuid-006' }

      it 'allows update to confirmed_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('confirmed_faculty')
      end

      it 'allows update to pending_faculty' do
        sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
        stub_salesforce_contacts([sf_contact])

        described_class.call

        expect(user.reload.faculty_status).to eq('pending_faculty')
      end
    end
  end

  describe 'SecurityLog creation for faculty status changes' do
    before { stub_sentry }
    let!(:user) { FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'test-uuid-007', salesforce_contact_id: 'SF_CONTACT_001' }

    it 'creates a SecurityLog when faculty status changes' do
      sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'confirmed_faculty')
      stub_salesforce_contacts([sf_contact])

      expect {
        described_class.call
      }.to change { SecurityLog.count }.by(1)

      log = SecurityLog.last
      expect(log.event_type).to eq('salesforce_updated_faculty_status')
      expect(log.event_data['old_status']).to eq('no_faculty_info')
      expect(log.event_data['new_status']).to eq('confirmed_faculty')
    end

    it 'does not create a SecurityLog when faculty status is preserved' do
      user.update!(faculty_status: :confirmed_faculty)
      sf_contact = create_sf_contact(uuid: user.uuid, faculty_verified: 'pending_faculty')
      stub_salesforce_contacts([sf_contact])

      # Faculty status is preserved, so no SecurityLog should be created
      expect {
        described_class.call
      }.not_to change { SecurityLog.count }
    end
  end

  describe 'unknown faculty_verified value handling' do
    before { stub_sentry }
    let!(:user) { FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'test-uuid-008' }
    let!(:other_user) do
      FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'test-uuid-009'
    end

    it 'skips the bad contact, reports it, and keeps updating the rest of the batch' do
      bad_contact = create_sf_contact(
        uuid: user.uuid, faculty_verified: 'unknown_status', contact_id: 'SF_CONTACT_BAD'
      )
      good_contact = create_sf_contact(
        uuid: other_user.uuid, faculty_verified: 'confirmed_faculty', contact_id: 'SF_CONTACT_GOOD'
      )
      stub_salesforce_contacts([bad_contact, good_contact])

      expect(Sentry).to receive(:capture_exception).with(
        instance_of(UpdateUserContactInfo::UnknownFacultyVerifiedError),
        extra: { user_id: user.id, salesforce_contact_id: 'SF_CONTACT_BAD' }
      )

      expect { described_class.call }.not_to raise_error

      expect(user.reload.faculty_status).to eq('no_faculty_info')
      expect(other_user.reload.faculty_status).to eq('confirmed_faculty')
    end
  end

  describe 'per-record error isolation' do
    before { stub_sentry }
    let!(:bad_user) { FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'test-uuid-010' }
    let!(:good_user) do
      FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'test-uuid-011'
    end

    it "doesn't let a RecordInvalid on one user stop the rest of the batch" do
      bad_contact = create_sf_contact(
        uuid: bad_user.uuid, faculty_verified: 'confirmed_faculty', contact_id: 'SF_CONTACT_INVALID'
      )
      good_contact = create_sf_contact(
        uuid: good_user.uuid, faculty_verified: 'confirmed_faculty', contact_id: 'SF_CONTACT_VALID'
      )
      stub_salesforce_contacts([bad_contact, good_contact])

      original_save = User.instance_method(:save!)
      allow_any_instance_of(User).to receive(:save!) do |instance|
        raise ActiveRecord::RecordInvalid, instance if instance.uuid == bad_user.uuid

        original_save.bind(instance).call
      end

      expect(Sentry).to receive(:capture_exception).with(
        instance_of(ActiveRecord::RecordInvalid),
        extra: { user_id: bad_user.id, salesforce_contact_id: 'SF_CONTACT_INVALID' }
      )

      expect { described_class.call }.not_to raise_error

      expect(bad_user.reload.faculty_status).to eq('no_faculty_info')
      expect(good_user.reload.faculty_status).to eq('confirmed_faculty')
    end
  end

  describe '#window_start' do
    it 'falls back to number_of_days_contacts_modified.days.ago when there is no watermark' do
      Settings::Db.store.number_of_days_contacts_modified = 3
      Settings::Salesforce.contacts_synced_through = nil

      travel_to(Time.current) do
        expect(described_class.new.window_start).to be_within(1.second).of(3.days.ago)
      end
    end

    it 'uses the watermark minus the 15 minute overlap when a watermark is set' do
      watermark = Time.utc(2026, 9, 20, 12, 0, 0)
      Settings::Salesforce.contacts_synced_through = watermark

      expect(described_class.new.window_start).to eq(watermark - 15.minutes)
    end
  end

  describe '#contact_batch_query' do
    it 'builds the LastModifiedDate filter, ordering and limit, without an Id cursor' do
      since = Time.utc(2026, 9, 24, 0, 0, 0)

      soql = described_class.new.contact_batch_query(since: since).to_s

      expect(soql).to include('LastModifiedDate >= 2026-09-24T00:00:00Z')
      expect(soql).to include('ORDER BY Id')
      expect(soql).to include('LIMIT 2000')
      expect(soql).not_to include('Id >')
    end

    it 'adds an Id cursor when after_id is given' do
      since = Time.utc(2026, 9, 24, 0, 0, 0)

      soql = described_class.new.contact_batch_query(since: since, after_id: 'CONTACT123').to_s

      expect(soql).to include("Id > 'CONTACT123'")
    end
  end

  describe 'watermark on a successful run' do
    before { stub_sentry }

    it 'sets contacts_synced_through to the run start time, not the run end time' do
      run_started_at = nil

      allow_any_instance_of(described_class).to receive(:salesforce_contact_batch) do
        run_started_at ||= Time.current
        travel 5.minutes
        []
      end

      described_class.call

      expect(Settings::Salesforce.contacts_synced_through).to be_within(1.second).of(run_started_at)
    end
  end

  describe 'a failed run' do
    it 'propagates the error, leaves the watermark unchanged, and reports :error to the check-in' do
      original_watermark = Time.utc(2026, 9, 20, 0, 0, 0)
      Settings::Salesforce.contacts_synced_through = original_watermark

      allow(Sentry).to receive(:capture_check_in).and_return('the-check-in-id')
      allow(Sentry).to receive(:capture_message)
      allow_any_instance_of(described_class).to(
        receive(:salesforce_contact_batch).and_raise(StandardError, 'salesforce is down')
      )

      expect { described_class.call }.to raise_error(StandardError, 'salesforce is down')

      expect(Sentry).to have_received(:capture_check_in).with(
        UpdateUserContactInfo::CHECK_IN_SLUG, :error, check_in_id: 'the-check-in-id'
      )
      expect(Settings::Salesforce.contacts_synced_through).to eq(original_watermark)
    end
  end

  describe 'the Sentry cron monitor schedule' do
    it 'sends a monitor_config matching the cron:10-to-half-hour schedule on in_progress' do
      allow(Sentry).to receive(:capture_check_in).and_return('check_in_id')
      allow(Sentry).to receive(:capture_message)
      stub_salesforce_contacts([])

      described_class.call

      expect(Sentry).to have_received(:capture_check_in).with(
        UpdateUserContactInfo::CHECK_IN_SLUG,
        :in_progress,
        monitor_config: an_object_having_attributes(
          schedule: an_object_having_attributes(value: '20,50 * * * *')
        )
      )
    end
  end

  describe 'pagination' do
    before { stub_sentry }
    let!(:page_user_one) do
      FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'page-uuid-1'
    end
    let!(:page_user_two) do
      FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'page-uuid-2'
    end
    let!(:page_user_three) do
      FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'page-uuid-3'
    end

    it 'requests the next page using the last id as the cursor, then stops on a short page' do
      stub_const('UpdateUserContactInfo::BATCH_SIZE', 2)

      contact1 = create_sf_contact(
        uuid: page_user_one.uuid, faculty_verified: 'confirmed_faculty', contact_id: 'C001'
      )
      contact2 = create_sf_contact(
        uuid: page_user_two.uuid, faculty_verified: 'confirmed_faculty', contact_id: 'C002'
      )
      contact3 = create_sf_contact(
        uuid: page_user_three.uuid, faculty_verified: 'confirmed_faculty', contact_id: 'C003'
      )

      after_ids = []
      allow_any_instance_of(described_class).to(
        receive(:salesforce_contact_batch) { |_instance, **kwargs|
          after_id = kwargs[:after_id]
          after_ids << after_id
          after_id.nil? ? [contact1, contact2] : [contact3]
        }
      )

      described_class.call

      expect(after_ids).to eq([nil, 'C002'])
      expect(page_user_one.reload.faculty_status).to eq('confirmed_faculty')
      expect(page_user_two.reload.faculty_status).to eq('confirmed_faculty')
      expect(page_user_three.reload.faculty_status).to eq('confirmed_faculty')
    end
  end
end
