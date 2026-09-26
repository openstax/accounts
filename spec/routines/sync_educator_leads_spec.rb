require 'rails_helper'

describe SyncEducatorLeads do
  before do
    stub_sentry
    Settings::Salesforce.push_incomplete_signup_leads_enabled = true
    allow(UpdateUserLeadInfo).to receive(:call)
  end

  def stub_lead_creation(lead_saved:, lead_id: 'SF_LEAD_NEW')
    lead = instance_double(OpenStax::Salesforce::Remote::Lead, id: lead_id)
    outputs = Lev::Outputs.new(lead_saved: lead_saved, lead: lead)
    result = Lev::Routine::Result.new(outputs, Lev::Errors.new)
    allow(Newflow::CreateOrUpdateSalesforceLead).to receive(:call).and_return(result)
    result
  end

  let!(:stalled_instructor) do
    FactoryBot.create(
      :user, role: :instructor, state: 'activated', salesforce_lead_id: nil,
             salesforce_contact_id: nil, created_at: 25.hours.ago
    )
  end

  describe 'the selection predicate' do
    it 'includes an educator whose signup stalled more than 24 hours ago with no lead or contact' do
      stub_lead_creation(lead_saved: true)

      described_class.call

      expect(Newflow::CreateOrUpdateSalesforceLead).to have_received(:call).with(user: stalled_instructor)
    end

    it 'excludes students' do
      student = FactoryBot.create(
        :user, role: :student, state: 'activated', salesforce_lead_id: nil,
               salesforce_contact_id: nil, created_at: 25.hours.ago
      )
      stub_lead_creation(lead_saved: true)

      described_class.call

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to have_received(:call).with(user: student)
    end

    it 'excludes unknown_role users' do
      unknown = FactoryBot.create(
        :user, role: :unknown_role, state: 'activated', salesforce_lead_id: nil,
               salesforce_contact_id: nil, created_at: 25.hours.ago
      )
      stub_lead_creation(lead_saved: true)

      described_class.call

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to have_received(:call).with(user: unknown)
    end

    it 'excludes users not in the activated state' do
      unverified = FactoryBot.create(
        :user, role: :instructor, state: 'unverified', salesforce_lead_id: nil,
               salesforce_contact_id: nil, created_at: 25.hours.ago
      )
      stub_lead_creation(lead_saved: true)

      described_class.call

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to have_received(:call).with(user: unverified)
    end

    it 'excludes users who already have a salesforce_lead_id' do
      has_lead = FactoryBot.create(
        :user, role: :instructor, state: 'activated', salesforce_lead_id: 'SF_LEAD_EXISTING',
               salesforce_contact_id: nil, created_at: 25.hours.ago
      )
      stub_lead_creation(lead_saved: true)

      described_class.call

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to have_received(:call).with(user: has_lead)
    end

    it 'excludes users who already have a salesforce_contact_id' do
      has_contact = FactoryBot.create(
        :user, role: :instructor, state: 'activated', salesforce_lead_id: nil,
               salesforce_contact_id: 'SF_CONTACT_EXISTING', created_at: 25.hours.ago
      )
      stub_lead_creation(lead_saved: true)

      described_class.call

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to have_received(:call).with(user: has_contact)
    end

    it 'excludes signups less than 24 hours old' do
      too_recent = FactoryBot.create(
        :user, role: :instructor, state: 'activated', salesforce_lead_id: nil,
               salesforce_contact_id: nil, created_at: 1.hour.ago
      )
      stub_lead_creation(lead_saved: true)

      described_class.call

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to have_received(:call).with(user: too_recent)
    end
  end

  describe 'ordering and batch limit' do
    it 'processes oldest signups first and caps at LEAD_BATCH_LIMIT' do
      stub_const('SyncEducatorLeads::LEAD_BATCH_LIMIT', 1)
      newer_stalled = FactoryBot.create(
        :user, role: :instructor, state: 'activated', salesforce_lead_id: nil,
               salesforce_contact_id: nil, created_at: 26.hours.ago
      )
      stalled_instructor.update!(created_at: 48.hours.ago)
      stub_lead_creation(lead_saved: true)

      described_class.call

      expect(Newflow::CreateOrUpdateSalesforceLead).to have_received(:call).once
      expect(Newflow::CreateOrUpdateSalesforceLead).to have_received(:call).with(user: stalled_instructor)
      expect(Newflow::CreateOrUpdateSalesforceLead).not_to have_received(:call).with(user: newer_stalled)
    end
  end

  describe 'the feature flag' do
    it 'pushes nothing when push_incomplete_signup_leads_enabled is false' do
      Settings::Salesforce.push_incomplete_signup_leads_enabled = false
      stub_lead_creation(lead_saved: true)

      described_class.call

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to have_received(:call)
    end

    it 'still runs the lead sync (pass 2) when the flag is off' do
      Settings::Salesforce.push_incomplete_signup_leads_enabled = false

      described_class.call

      expect(UpdateUserLeadInfo).to have_received(:call)
    end
  end

  describe 'logging a created lead' do
    it 'logs incomplete_signup_lead_created with the lead id when the lead was saved' do
      stub_lead_creation(lead_saved: true, lead_id: 'SF_LEAD_777')

      described_class.call

      log = SecurityLog.find_by(event_type: 'incomplete_signup_lead_created', user: stalled_instructor)
      expect(log).not_to be_nil
      expect(log.event_data['lead_id']).to eq('SF_LEAD_777')
    end

    it 'does not log when the lead was not saved' do
      stub_lead_creation(lead_saved: false)

      described_class.call

      expect(
        SecurityLog.where(event_type: 'incomplete_signup_lead_created', user: stalled_instructor)
      ).to be_empty
    end
  end

  describe 'exception isolation' do
    it "reports one user's failure to Sentry and keeps processing the rest" do
      other_stalled = FactoryBot.create(
        :user, role: :instructor, state: 'activated', salesforce_lead_id: nil,
               salesforce_contact_id: nil, created_at: 26.hours.ago
      )
      good_result = stub_lead_creation(lead_saved: true)
      allow(Newflow::CreateOrUpdateSalesforceLead).to receive(:call) do |user:|
        raise StandardError, 'salesforce is down' if user == other_stalled

        good_result
      end

      expect(Sentry).to receive(:capture_exception).with(
        instance_of(StandardError), extra: { user_id: other_stalled.id }
      )

      expect { described_class.call }.not_to raise_error

      expect(
        SecurityLog.where(event_type: 'incomplete_signup_lead_created', user: stalled_instructor)
      ).not_to be_empty
    end
  end

  describe '#call' do
    it 'runs the lead-creation pass followed by UpdateUserLeadInfo' do
      stub_lead_creation(lead_saved: true)

      described_class.call

      expect(UpdateUserLeadInfo).to have_received(:call)
    end
  end
end
