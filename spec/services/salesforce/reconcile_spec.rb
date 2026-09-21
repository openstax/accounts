require 'rails_helper'

RSpec.describe Salesforce::Reconcile do
  before do
    Settings::FeatureFlags.salesforce_reconcile_self_heal = true
    stub_sentry
  end

  after { Settings::FeatureFlags.salesforce_reconcile_self_heal = false }

  # --- Pass 1: contact-anchored ---

  describe 'Pass 1' do
    let!(:user) { FactoryBot.create(:user, salesforce_contact_id: 'C1') }

    it 'no-ops when stored contact is live and owns the user' do
      contact = Salesforce::Records::Contact.new(
        id: 'C1', accounts_uuid: user.uuid, master_record_id: nil, is_deleted: false
      )
      allow_any_instance_of(described_class).to receive(:fetch_contacts_by_id).and_return({ 'C1' => contact })
      allow_any_instance_of(described_class).to receive(:run_pass_2)
      allow_any_instance_of(described_class).to receive(:run_pass_3)
      allow_any_instance_of(described_class).to receive(:sweep_sf_orphans)
      described_class.call
      expect(user.reload.salesforce_contact_id).to eq('C1')
      expect(SecurityLog.where(event_type: 'salesforce_reconcile_user_ok', user: user)).to exist
    end

    it 'follows a merge to the master record when the master owns the user' do
      merged = Salesforce::Records::Contact.new(
        id: 'C1', accounts_uuid: user.uuid, master_record_id: 'NEW', is_deleted: false
      )
      master = Salesforce::Records::Contact.new(
        id: 'NEW', accounts_uuid: user.uuid, master_record_id: nil, is_deleted: false
      )
      allow_any_instance_of(described_class).to receive(:fetch_contacts_by_id).and_return({ 'C1' => merged })
      allow(Salesforce::Records::Contact).to receive(:find).with('NEW').and_return(master)
      allow_any_instance_of(described_class).to receive(:run_pass_2)
      allow_any_instance_of(described_class).to receive(:run_pass_3)
      allow_any_instance_of(described_class).to receive(:sweep_sf_orphans)
      described_class.call
      expect(user.reload.salesforce_contact_id).to eq('NEW')
      expect(SecurityLog.where(event_type: 'salesforce_reconcile_followed_merge', user: user)).to exist
    end

    it 'clears + reattaches via Lookup when stored contact is deleted' do
      allow_any_instance_of(described_class).to receive(:fetch_contacts_by_id).and_return({})
      allow(Salesforce::Lookup).to receive(:contact_for).with(user).and_return(nil)
      allow_any_instance_of(described_class).to receive(:run_pass_2)
      allow_any_instance_of(described_class).to receive(:run_pass_3)
      allow_any_instance_of(described_class).to receive(:sweep_sf_orphans)
      described_class.call
      expect(user.reload.salesforce_contact_id).to be_nil
      expect(SalesforceDriftFinding.where(user: user, category: 'sf_contact_uuid_mismatch')).to exist
    end

    it 'with self_heal flag off, opens finding but does not mutate the user' do
      Settings::FeatureFlags.salesforce_reconcile_self_heal = false
      allow_any_instance_of(described_class).to receive(:fetch_contacts_by_id).and_return({})
      allow_any_instance_of(described_class).to receive(:run_pass_2)
      allow_any_instance_of(described_class).to receive(:run_pass_3)
      allow_any_instance_of(described_class).to receive(:sweep_sf_orphans)
      described_class.call
      expect(user.reload.salesforce_contact_id).to eq('C1')
      expect(SalesforceDriftFinding.where(user: user, category: 'sf_contact_uuid_mismatch')).to exist
    end
  end

  # --- Pass 2: lead-anchored ---

  describe 'Pass 2' do
    let!(:user) { FactoryBot.create(:user, salesforce_contact_id: nil, salesforce_lead_id: 'L1') }

    it "attaches the converted lead's Contact when it owns the user" do
      lead = Salesforce::Records::Lead.new(
        id: 'L1', accounts_uuid: user.uuid, is_converted: true, converted_contact_id: 'CC1'
      )
      contact = Salesforce::Records::Contact.new(
        id: 'CC1', accounts_uuid: user.uuid, master_record_id: nil, is_deleted: false
      )
      allow_any_instance_of(described_class).to receive(:run_pass_1)
      allow_any_instance_of(described_class).to receive(:fetch_leads_by_id).and_return({ 'L1' => lead })
      allow(Salesforce::Records::Contact).to receive(:find).with('CC1').and_return(contact)
      allow_any_instance_of(described_class).to receive(:run_pass_3)
      allow_any_instance_of(described_class).to receive(:sweep_sf_orphans)
      described_class.call
      expect(user.reload.salesforce_contact_id).to eq('CC1')
      expect(SecurityLog.where(event_type: 'salesforce_reconcile_attached_from_conversion', user: user)).to exist
    end

    it 'opens a finding when the stored lead is gone' do
      allow_any_instance_of(described_class).to receive(:run_pass_1)
      allow_any_instance_of(described_class).to receive(:fetch_leads_by_id).and_return({})
      allow(Salesforce::Lookup).to receive(:contact_for).with(user).and_return(nil)
      allow_any_instance_of(described_class).to receive(:run_pass_3)
      allow_any_instance_of(described_class).to receive(:sweep_sf_orphans)
      described_class.call
      expect(SalesforceDriftFinding.where(user: user, category: 'sf_lead_uuid_mismatch')).to exist
    end
  end

  # --- Pass 3 ---

  describe 'Pass 3' do
    let!(:user3) do
      FactoryBot.create(:user,
        salesforce_contact_id: nil, salesforce_lead_id: nil,
        is_profile_complete: true, role: 'instructor', faculty_status: 'pending_faculty')
    end

    it 'attaches a Contact found by accounts_uuid' do
      contact = Salesforce::Records::Contact.new(
        id: 'C3', accounts_uuid: user3.uuid, master_record_id: nil, is_deleted: false
      )
      allow_any_instance_of(described_class).to receive(:run_pass_1)
      allow_any_instance_of(described_class).to receive(:run_pass_2)
      allow(Salesforce::Records::Contact).to receive(:where).with(accounts_uuid: [user3.uuid]).and_return([contact])
      allow(Salesforce::Records::Lead).to receive(:where).with(accounts_uuid: [user3.uuid]).and_return([])
      allow_any_instance_of(described_class).to receive(:sweep_sf_orphans)
      described_class.call
      expect(user3.reload.salesforce_contact_id).to eq('C3')
      expect(SecurityLog.where(event_type: 'salesforce_link_restored_by_reconcile', user: user3)).to exist
    end

    it 'opens user_unlinked_eligible finding when neither found' do
      allow_any_instance_of(described_class).to receive(:run_pass_1)
      allow_any_instance_of(described_class).to receive(:run_pass_2)
      allow(Salesforce::Records::Contact).to receive(:where).with(accounts_uuid: [user3.uuid]).and_return([])
      allow(Salesforce::Records::Lead).to receive(:where).with(accounts_uuid: [user3.uuid]).and_return([])
      allow_any_instance_of(described_class).to receive(:sweep_sf_orphans)
      described_class.call
      expect(SalesforceDriftFinding.where(user: user3, category: 'user_unlinked_eligible')).to exist
    end
  end

  # --- Finalize ---

  describe 'finalize_findings' do
    it 'closes open findings not refreshed during this run' do
      stale = FactoryBot.create(:salesforce_drift_finding,
        category: 'sf_orphan_contact', last_seen_at: 2.days.ago, resolved_at: nil)
      allow_any_instance_of(described_class).to receive(:run_pass_1)
      allow_any_instance_of(described_class).to receive(:run_pass_2)
      allow_any_instance_of(described_class).to receive(:run_pass_3)
      allow_any_instance_of(described_class).to receive(:sweep_sf_orphans)
      described_class.call
      expect(stale.reload.resolved_at).not_to be_nil
    end

    it 'fires drift_findings_total_open alert when threshold exceeded' do
      Settings::Db.store.salesforce_alert_drift_open_total = 0
      # Create with last_seen_at in the future so finalize doesn't auto-close it
      FactoryBot.create(:salesforce_drift_finding, resolved_at: nil, last_seen_at: 1.hour.from_now)
      allow_any_instance_of(described_class).to receive(:run_pass_1)
      allow_any_instance_of(described_class).to receive(:run_pass_2)
      allow_any_instance_of(described_class).to receive(:run_pass_3)
      allow_any_instance_of(described_class).to receive(:sweep_sf_orphans)
      expect(Sentry).to receive(:capture_message).with(/drift_findings_total_open/, anything)
      described_class.call
    ensure
      Settings::Db.store.salesforce_alert_drift_open_total = 100
    end
  end
end
