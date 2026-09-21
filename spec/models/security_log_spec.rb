require 'rails_helper'

describe SecurityLog, type: :model do
  subject(:security_log) { FactoryBot.create :security_log }

  it { should validate_presence_of :event_type }

  it 'cannot be updated' do
    expect{security_log.save}.to raise_error ActiveRecord::ReadOnlyRecord
    expect{security_log.save!}.to raise_error ActiveRecord::ReadOnlyRecord
    expect{security_log.update_attribute :event_type, :admin_created}.to(
      raise_error ActiveRecord::ReadOnlyRecord
    )
    expect{security_log.update event_type: :admin_created}.to(
      raise_error ActiveRecord::ReadOnlyRecord
    )
  end

  it 'cannot be destroyed' do
    expect{security_log.destroy}.to raise_error ActiveRecord::ReadOnlyRecord
  end

  it 'includes the new salesforce event types added in the sync redesign' do
    %i[
      salesforce_lookup_started
      salesforce_lookup_matched_by_uuid
      salesforce_upsert_lead_saved
      salesforce_upsert_lead_save_failed
      salesforce_lead_id_persist_failed
      salesforce_stale_contact_id_cleared
      salesforce_contact_id_swapped
      salesforce_contact_id_conflict
      salesforce_contact_skipped_merged_or_deleted
      salesforce_user_school_not_cached
      salesforce_reconcile_contact_id_cleared
      salesforce_reconcile_followed_merge
      salesforce_link_restored_by_reconcile
      salesforce_contact_id_orphaned
    ].each do |sym|
      expect(SecurityLog.event_types).to have_key(sym.to_s)
    end
  end
end
