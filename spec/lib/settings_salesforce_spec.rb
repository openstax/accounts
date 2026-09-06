require 'rails_helper'

RSpec.describe Settings::Salesforce do
  describe 'contacts_synced_through' do
    after { Settings::Db.store.salesforce_contacts_synced_through = nil }

    it 'round-trips a UTC time as ISO8601' do
      t = Time.utc(2026, 5, 1, 12, 0, 0)
      Settings::Salesforce.contacts_synced_through = t
      expect(Settings::Salesforce.contacts_synced_through).to eq(t)
    end

    it 'returns nil when unset' do
      Settings::Db.store.salesforce_contacts_synced_through = nil
      expect(Settings::Salesforce.contacts_synced_through).to be_nil
    end
  end

  it 'exposes reconcile_max_queries default' do
    expect(Settings::Salesforce.reconcile_max_queries).to eq(5000)
  end

  it 'exposes alert thresholds' do
    expect(Settings::Salesforce.alert_contact_id_conflict_count).to eq(5)
    expect(Settings::Salesforce.alert_contact_id_swap_rate_pct).to eq(5)
    expect(Settings::Salesforce.alert_drift_open_total).to eq(100)
  end

  it 'exposes the feature flag through Settings::FeatureFlags' do
    expect(Settings::FeatureFlags.salesforce_reconcile_self_heal).to be(false)
    Settings::FeatureFlags.salesforce_reconcile_self_heal = true
    expect(Settings::FeatureFlags.salesforce_reconcile_self_heal).to be(true)
  ensure
    Settings::FeatureFlags.salesforce_reconcile_self_heal = false
  end
end
