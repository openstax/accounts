require 'rails_helper'

RSpec.describe Salesforce::UpsertLead do
  let!(:home) { FactoryBot.create(:school, name: 'Find Me A Home', salesforce_id: 'SF_HOME') }

  let(:user) do
    FactoryBot.create(:user,
      role: 'instructor', state: 'activated', is_newflow: true,
      using_openstax_how: 'as_primary', is_profile_complete: true,
      self_reported_school: 'Test U', school: home,
      faculty_status: 'pending_faculty')
  end

  let(:lead) { Salesforce::Records::Lead.new(email: 'x@y.com', accounts_uuid: user.uuid) }

  before do
    allow(Sentry).to receive(:capture_message)
    allow(Salesforce::Records::School).to receive(:find_by)
      .with({ name: 'Find Me A Home' }).and_return(OpenStruct.new(id: 'SF_HOME'))
    allow(user).to receive(:best_email_address_for_salesforce).and_return('x@y.com')
    allow(User).to receive(:find).and_return(user)
  end

  context 'creating a new lead when lookup returns nothing' do
    before do
      allow(Salesforce::Lookup).to receive(:lead_for).with(user)
        .and_return(Salesforce::Lookup::Result.new(lead: nil, matched_by: nil))
      allow(Salesforce::Records::Lead).to receive(:new).and_return(lead)
      allow(lead).to receive(:save).and_return(true)
      allow(lead).to receive(:id).and_return('NEW_LEAD')
    end

    it 'persists the new lead id on the user' do
      described_class.call(user: user)
      expect(user.reload.salesforce_lead_id).to eq('NEW_LEAD')
    end

    it 'records the upsert_lead_saved audit event' do
      described_class.call(user: user)
      expect(SecurityLog.where(event_type: 'salesforce_upsert_lead_saved', user: user)).to exist
    end
  end

  context 'when user.save fails the first time and succeeds on retry' do
    before do
      allow(Salesforce::Lookup).to receive(:lead_for).with(user)
        .and_return(Salesforce::Lookup::Result.new(lead: nil, matched_by: nil))
      allow(Salesforce::Records::Lead).to receive(:new).and_return(lead)
      allow(lead).to receive(:save).and_return(true)
      allow(lead).to receive(:id).and_return('NEW_LEAD')
    end

    it 'retries the local save and records a retry audit event' do
      call_count = 0
      original_save = user.method(:save)
      allow(user).to receive(:save) do
        call_count += 1
        call_count >= 2 ? original_save.call : false
      end
      described_class.call(user: user)
      expect(call_count).to be >= 2
      expect(SecurityLog.where(event_type: 'salesforce_lead_id_persist_retry', user: user)).to exist
    end
  end

  context 'when user.save fails 3 times' do
    before do
      allow(Salesforce::Lookup).to receive(:lead_for).with(user)
        .and_return(Salesforce::Lookup::Result.new(lead: nil, matched_by: nil))
      allow(Salesforce::Records::Lead).to receive(:new).and_return(lead)
      allow(lead).to receive(:save).and_return(true)
      allow(lead).to receive(:id).and_return('NEW_LEAD')
      allow_any_instance_of(User).to receive(:save).and_return(false)
      allow_any_instance_of(User).to receive(:reload).and_return(user)
    end

    it 'logs persist_failed loudly and to Sentry' do
      expect(Sentry).to receive(:capture_message).with(/lead_id persist failed/)
      described_class.call(user: user)
      expect(SecurityLog.where(event_type: 'salesforce_lead_id_persist_failed', user: user)).to exist
    end
  end

  context 'when user already has a verifying contact' do
    it 'returns early without saving a lead' do
      user.update!(salesforce_contact_id: 'C1')
      owning_contact = Salesforce::Records::Contact.new(
        id: 'C1', accounts_uuid: user.uuid, master_record_id: nil, is_deleted: false
      )
      allow(Salesforce::Lookup).to receive(:contact_for).with(user).and_return(owning_contact)
      allow(Salesforce::Lookup).to receive(:lead_for).with(user)
        .and_return(Salesforce::Lookup::Result.new(lead: nil, matched_by: nil))
      expect(Salesforce::Records::Lead).not_to receive(:new)
      described_class.call(user: user)
      expect(SecurityLog.where(event_type: 'salesforce_upsert_lead_skipped_user_has_contact', user: user)).to exist
    end
  end

  context 'when user has a stored contact_id that no longer owns them' do
    it 'clears it and proceeds to create a lead' do
      user.update!(salesforce_contact_id: 'C_STALE')
      allow(Salesforce::Lookup).to receive(:contact_for).with(user).and_return(nil)
      allow(Salesforce::Lookup).to receive(:lead_for).with(user)
        .and_return(Salesforce::Lookup::Result.new(lead: nil, matched_by: nil))
      allow(Salesforce::Records::Lead).to receive(:new).and_return(lead)
      allow(lead).to receive(:save).and_return(true)
      allow(lead).to receive(:id).and_return('NEW_LEAD')
      described_class.call(user: user)
      expect(SecurityLog.where(event_type: 'salesforce_stale_contact_id_cleared', user: user)).to exist
      expect(user.reload.salesforce_contact_id).to be_nil
    end
  end

  context 'when the fallback SF School is not yet cached locally' do
    it 'creates a stub local School so the saved Lead still has account_id / school_id' do
      # Use a fresh SF id that has no local School row, so we exercise the
      # cache-miss branch without fighting the foreign key on the let!(:home)
      # School the outer fixture created.
      uncached_sf_id = 'SF_UNCACHED_HOME'
      expect(School.where(salesforce_id: uncached_sf_id)).to be_empty
      user.update!(school: nil)

      # SF says the fallback exists at the uncached id.
      allow(Salesforce::Records::School).to receive(:find_by)
        .with({ name: 'Find Me A Home' })
        .and_return(OpenStruct.new(id: uncached_sf_id, name: 'Find Me A Home'))
      allow(Salesforce::Lookup).to receive(:lead_for).with(user)
        .and_return(Salesforce::Lookup::Result.new(lead: nil, matched_by: nil))
      allow(Salesforce::Records::Lead).to receive(:new).and_return(lead)
      allow(lead).to receive(:save).and_return(true)
      allow(lead).to receive(:id).and_return('NEW_LEAD')

      expect {
        described_class.call(user: user)
      }.to change { School.where(salesforce_id: uncached_sf_id).count }.from(0).to(1)

      expect(user.reload.school&.salesforce_id).to eq(uncached_sf_id)
      expect(lead.account_id).to eq(uncached_sf_id)
      expect(lead.school_id).to eq(uncached_sf_id)
    end
  end
end
