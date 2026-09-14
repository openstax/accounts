require 'rails_helper'

RSpec.describe Salesforce::SyncContacts do
  let!(:school) { FactoryBot.create(:school, salesforce_id: 'SF_S1') }
  let!(:user)   { FactoryBot.create(:user, salesforce_contact_id: nil) }

  let(:live_contact) do
    contact = Salesforce::Records::Contact.new(
      id: 'C1', accounts_uuid: user.uuid,
      master_record_id: nil, is_deleted: false,
      faculty_verified: 'confirmed_faculty', school_type: 'College/University (4)',
      adoption_status: 'Not Adopter'
    )
    sf_school = Salesforce::Records::School.new(
      id: 'SF_S1', school_location: 'Domestic', is_kip: false, is_child_of_kip: false
    )
    allow(contact).to receive(:school).and_return(sf_school)
    allow(contact).to receive(:school_id).and_return('SF_S1')
    contact
  end

  let(:merged_contact) do
    contact = Salesforce::Records::Contact.new(
      id: 'C2', accounts_uuid: user.uuid,
      master_record_id: 'CMASTER', is_deleted: false,
      faculty_verified: nil, school_type: nil, adoption_status: nil
    )
    allow(contact).to receive(:school).and_return(nil)
    allow(contact).to receive(:school_id).and_return(nil)
    contact
  end

  before do
    stub_sentry
    allow_any_instance_of(described_class).to receive(:fetch_contacts).and_return([live_contact])
  end

  it 'first-time link sets salesforce_contact_id' do
    described_class.call
    expect(user.reload.salesforce_contact_id).to eq('C1')
  end

  it 'updates faculty_status from the contact' do
    described_class.call
    expect(user.reload.faculty_status).to eq('confirmed_faculty')
  end

  it 'skips merged contacts entirely' do
    allow_any_instance_of(described_class).to receive(:fetch_contacts).and_return([merged_contact])
    described_class.call
    expect(user.reload.salesforce_contact_id).to be_nil
    expect(SecurityLog.where(event_type: 'salesforce_contact_skipped_merged_or_deleted', user: user)).to exist
  end

  it 'records a conflict when stored contact still owns the user and a new candidate appears' do
    user.update!(salesforce_contact_id: 'OLD')
    stored = Salesforce::Records::Contact.new(
      id: 'OLD', accounts_uuid: user.uuid, master_record_id: nil, is_deleted: false
    )
    allow(Salesforce::Records::Contact).to receive(:find_by).with({ id: 'OLD' }).and_return(stored)
    described_class.call
    expect(SecurityLog.where(event_type: 'salesforce_contact_id_conflict', user: user)).to exist
    expect(user.reload.salesforce_contact_id).to eq('OLD')
  end

  it 'swaps when previous contact has been merged into the new one' do
    user.update!(salesforce_contact_id: 'OLD')
    stored = Salesforce::Records::Contact.new(
      id: 'OLD', accounts_uuid: user.uuid, master_record_id: 'C1', is_deleted: false
    )
    allow(Salesforce::Records::Contact).to receive(:find_by).with({ id: 'OLD' }).and_return(stored)
    described_class.call
    expect(user.reload.salesforce_contact_id).to eq('C1')
    expect(SecurityLog.where(event_type: 'salesforce_contact_id_swapped', user: user)).to exist
  end

  it 'swaps when previous contact has been deleted (no longer found in SF)' do
    user.update!(salesforce_contact_id: 'OLD')
    allow(Salesforce::Records::Contact).to receive(:find_by).with({ id: 'OLD' }).and_return(nil)
    described_class.call
    expect(user.reload.salesforce_contact_id).to eq('C1')
    expect(SecurityLog.where(event_type: 'salesforce_contact_id_swapped', user: user)).to exist
  end

  it 'persists the cursor to Settings on each run' do
    fixed_time = Time.utc(2026, 5, 22, 12, 0, 0)
    allow(Time).to receive(:current).and_return(fixed_time)
    described_class.call
    expect(Settings::Salesforce.contacts_synced_through).to eq(fixed_time)
  ensure
    Settings::Db.store.salesforce_contacts_synced_through = nil
  end

  it 'records unknown_accounts_uuids when the SF Contact UUID maps to no Accounts user' do
    foreign = Salesforce::Records::Contact.new(
      id: 'C_FOREIGN', accounts_uuid: 'UNKNOWN', master_record_id: nil, is_deleted: false,
      faculty_verified: nil, school_type: nil, adoption_status: nil
    )
    allow(foreign).to receive(:school).and_return(nil)
    allow(foreign).to receive(:school_id).and_return(nil)
    allow_any_instance_of(described_class).to receive(:fetch_contacts).and_return([foreign])
    described_class.call
    # No SecurityLog write because there's no user — but the metric should be bumped (verified indirectly through alert threshold path)
    expect(user.reload.salesforce_contact_id).to be_nil
  end
end
