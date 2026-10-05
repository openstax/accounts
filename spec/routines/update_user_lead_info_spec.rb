require 'rails_helper'

describe UpdateUserLeadInfo, type: :routine do
  include ActiveSupport::Testing::TimeHelpers

  def create_sf_lead(uuid:, verification_status:, lead_id: 'SF_LEAD_001')
    OpenStax::Salesforce::Remote::Lead.new(
      id: lead_id,
      accounts_uuid: uuid,
      verification_status: verification_status
    )
  end

  def stub_salesforce_leads(leads)
    allow_any_instance_of(described_class).to(
      receive(:salesforce_lead_batch).and_return(leads)
    )
  end

  before { stub_sentry }

  it 'skips switched student leads so the resync does not overwrite the marker' do
    switched_user = FactoryBot.create(
      :user,
      role: User::STUDENT_ROLE,
      faculty_status: User::REJECTED_FACULTY,
      salesforce_lead_id: 'SF_LEAD_123',
      uuid: 'switched-user-uuid'
    )
    other_user = FactoryBot.create(
      :user,
      role: User::INSTRUCTOR_ROLE,
      faculty_status: User::INCOMPLETE_SIGNUP,
      salesforce_lead_id: 'SF_LEAD_456',
      uuid: 'other-user-uuid'
    )
    switched_lead = create_sf_lead(
      uuid: switched_user.uuid, verification_status: 'confirmed_faculty', lead_id: 'SF_LEAD_123'
    )
    other_lead = create_sf_lead(
      uuid: other_user.uuid, verification_status: 'confirmed_faculty', lead_id: 'SF_LEAD_456'
    )
    stub_salesforce_leads([switched_lead, other_lead])

    described_class.call

    expect(switched_user.reload.faculty_status).to eq(User::REJECTED_FACULTY)
    expect(other_user.reload.faculty_status).to eq(User::CONFIRMED_FACULTY)
  end

  describe 'adopting salesforce_lead_id' do
    let!(:user) do
      FactoryBot.create :user, uuid: 'uuid-1', faculty_status: :no_faculty_info, salesforce_lead_id: nil
    end

    it 'sets salesforce_lead_id and logs the change when it differs' do
      lead = create_sf_lead(uuid: user.uuid, verification_status: 'no_faculty_info', lead_id: 'SF_LEAD_NEW')
      stub_salesforce_leads([lead])

      described_class.call

      expect(user.reload.salesforce_lead_id).to eq('SF_LEAD_NEW')
      log = SecurityLog.find_by(event_type: 'user_lead_id_updated_from_salesforce')
      expect(log).not_to be_nil
      expect(log.event_data['new_lead_id']).to eq('SF_LEAD_NEW')
    end

    it 'does not log when the lead id is unchanged' do
      user.update!(salesforce_lead_id: 'SF_LEAD_SAME')
      lead = create_sf_lead(uuid: user.uuid, verification_status: 'no_faculty_info', lead_id: 'SF_LEAD_SAME')
      stub_salesforce_leads([lead])

      described_class.call

      expect(SecurityLog.where(event_type: 'user_lead_id_updated_from_salesforce')).to be_empty
    end
  end

  describe 'applying faculty status through the ladder' do
    let!(:user) { FactoryBot.create :user, uuid: 'uuid-2', faculty_status: :incomplete_signup }

    it 'applies an upgrade and logs both the ladder move and the sync event' do
      lead = create_sf_lead(uuid: user.uuid, verification_status: 'confirmed_faculty')
      stub_salesforce_leads([lead])

      described_class.call

      expect(user.reload.faculty_status).to eq('confirmed_faculty')
      expect(SecurityLog.where(event_type: 'faculty_status_advanced')).not_to be_empty
      synced = SecurityLog.find_by(event_type: 'salesforce_lead_status_synced')
      expect(synced.event_data['old_status']).to eq('incomplete_signup')
      expect(synced.event_data['new_status']).to eq('confirmed_faculty')
    end

    it 'refuses a downgrade and logs only the ladder refusal' do
      user.update!(faculty_status: :confirmed_faculty)
      lead = create_sf_lead(uuid: user.uuid, verification_status: 'incomplete_signup')
      stub_salesforce_leads([lead])

      expect { described_class.call }.to(
        change { SecurityLog.where(event_type: 'faculty_status_downgrade_refused').count }.by(1)
      )

      expect(user.reload.faculty_status).to eq('confirmed_faculty')
      expect(SecurityLog.where(event_type: 'salesforce_lead_status_synced')).to be_empty
    end

    it 'allows the CX flip from confirmed_faculty to rejected_faculty' do
      user.update!(faculty_status: :confirmed_faculty)
      lead = create_sf_lead(uuid: user.uuid, verification_status: 'rejected_faculty')
      stub_salesforce_leads([lead])

      described_class.call

      expect(user.reload.faculty_status).to eq('rejected_faculty')
    end

    it 'maps a nil verification_status to no_faculty_info, refused for a confirmed user' do
      user.update!(faculty_status: :confirmed_faculty)
      lead = create_sf_lead(uuid: user.uuid, verification_status: nil)
      stub_salesforce_leads([lead])

      described_class.call

      expect(user.reload.faculty_status).to eq('confirmed_faculty')
      expect(SecurityLog.where(event_type: 'faculty_status_downgrade_refused')).not_to be_empty
    end
  end

  describe 'unknown verification_status handling' do
    let!(:user) { FactoryBot.create :user, uuid: 'uuid-3', faculty_status: :no_faculty_info }
    let!(:other_user) { FactoryBot.create :user, uuid: 'uuid-4', faculty_status: :no_faculty_info }

    it 'skips the bad lead, reports it, and keeps updating the rest of the batch' do
      bad_lead = create_sf_lead(uuid: user.uuid, verification_status: 'unknown_status', lead_id: 'BAD')
      good_lead = create_sf_lead(uuid: other_user.uuid, verification_status: 'confirmed_faculty', lead_id: 'GOOD')
      stub_salesforce_leads([bad_lead, good_lead])

      expect(Sentry).to receive(:capture_exception).with(
        instance_of(UpdateUserLeadInfo::UnknownVerificationStatusError),
        extra: { user_id: user.id, salesforce_lead_id: 'BAD' }
      )

      expect { described_class.call }.not_to raise_error

      expect(user.reload.faculty_status).to eq('no_faculty_info')
      expect(other_user.reload.faculty_status).to eq('confirmed_faculty')
    end
  end

  describe '#window_start' do
    it 'falls back to 7 days ago, midnight UTC, when there is no watermark' do
      Settings::Salesforce.leads_synced_through = nil

      travel_to(Time.utc(2026, 9, 25, 15, 30, 0)) do
        expect(described_class.new.window_start).to eq(Time.utc(2026, 9, 18, 0, 0, 0))
      end
    end

    it 'uses the watermark minus the 15 minute overlap when a watermark is set' do
      watermark = Time.utc(2026, 9, 20, 12, 0, 0)
      Settings::Salesforce.leads_synced_through = watermark

      expect(described_class.new.window_start).to eq(watermark - 15.minutes)
    end
  end

  describe '#lead_batch_query' do
    it 'builds the filters, ordering and limit, without an Id cursor' do
      since = Time.utc(2026, 9, 24, 0, 0, 0)

      soql = described_class.new.lead_batch_query(since: since).to_s

      expect(soql).to include('Accounts_UUID__c != null')
      expect(soql).to include('IsConverted = false')
      expect(soql).to include('LastModifiedDate >= 2026-09-24T00:00:00Z')
      expect(soql).to include('ORDER BY Id')
      expect(soql).to include('LIMIT 2000')
      expect(soql).not_to include('Id >')
    end

    it 'adds an Id cursor when after_id is given' do
      since = Time.utc(2026, 9, 24, 0, 0, 0)

      soql = described_class.new.lead_batch_query(since: since, after_id: 'LEAD123').to_s

      expect(soql).to include("Id > 'LEAD123'")
    end
  end

  describe 'pagination' do
    let!(:page_user_one) { FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'page-uuid-1' }
    let!(:page_user_two) { FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'page-uuid-2' }
    let!(:page_user_three) { FactoryBot.create :user, faculty_status: :no_faculty_info, uuid: 'page-uuid-3' }

    it 'requests the next page using the last id as the cursor, then stops on a short page' do
      stub_const('UpdateUserLeadInfo::BATCH_SIZE', 2)

      lead1 = create_sf_lead(uuid: page_user_one.uuid, verification_status: 'confirmed_faculty', lead_id: 'L001')
      lead2 = create_sf_lead(uuid: page_user_two.uuid, verification_status: 'confirmed_faculty', lead_id: 'L002')
      lead3 = create_sf_lead(uuid: page_user_three.uuid, verification_status: 'confirmed_faculty', lead_id: 'L003')

      after_ids = []
      allow_any_instance_of(described_class).to(
        receive(:salesforce_lead_batch) { |_instance, **kwargs|
          after_id = kwargs[:after_id]
          after_ids << after_id
          after_id.nil? ? [lead1, lead2] : [lead3]
        }
      )

      described_class.call

      expect(after_ids).to eq([nil, 'L002'])
      expect(page_user_one.reload.faculty_status).to eq('confirmed_faculty')
      expect(page_user_two.reload.faculty_status).to eq('confirmed_faculty')
      expect(page_user_three.reload.faculty_status).to eq('confirmed_faculty')
    end
  end

  describe 'watermark on a successful run' do
    it 'sets leads_synced_through to the run start time, not the run end time' do
      run_started_at = nil

      allow_any_instance_of(described_class).to receive(:salesforce_lead_batch) do
        run_started_at ||= Time.current
        travel 5.minutes
        []
      end

      described_class.call

      expect(Settings::Salesforce.leads_synced_through).to be_within(1.second).of(run_started_at)
    end
  end

  describe 'a failed run' do
    it 'propagates the error, leaves the watermark unchanged, and reports :error to the check-in' do
      original_watermark = Time.utc(2026, 9, 20, 0, 0, 0)
      Settings::Salesforce.leads_synced_through = original_watermark

      allow(Sentry).to receive(:capture_check_in).and_return('the-check-in-id')
      allow_any_instance_of(described_class).to(
        receive(:salesforce_lead_batch).and_raise(StandardError, 'salesforce is down')
      )

      expect { described_class.call }.to raise_error(StandardError, 'salesforce is down')

      expect(Sentry).to have_received(:capture_check_in).with(
        UpdateUserLeadInfo::CHECK_IN_SLUG, :error, check_in_id: 'the-check-in-id'
      )
      expect(Settings::Salesforce.leads_synced_through).to eq(original_watermark)
    end
  end

  describe 'the Sentry cron monitor schedule' do
    it 'sends a monitor_config matching the cron:day schedule on in_progress' do
      stub_salesforce_leads([])

      described_class.call

      expect(Sentry).to have_received(:capture_check_in).with(
        UpdateUserLeadInfo::CHECK_IN_SLUG,
        :in_progress,
        monitor_config: an_object_having_attributes(
          schedule: an_object_having_attributes(value: '30 8 * * *')
        )
      )
    end
  end
end
