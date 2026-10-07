require 'rails_helper'

describe Settings::Salesforce, type: :lib do
  describe 'sync watermarks' do
    it 'read as nil while unset, so a blank admin field means "no watermark"' do
      Settings::Db.store.contacts_synced_through = ''
      Settings::Db.store.leads_synced_through = ''

      expect(described_class.contacts_synced_through).to be_nil
      expect(described_class.leads_synced_through).to be_nil
    end

    it 'round-trip a time in UTC' do
      time = Time.utc(2026, 9, 25, 20, 22, 12)
      described_class.leads_synced_through = time

      expect(described_class.leads_synced_through).to eq(time)
      expect(Settings::Db.store.leads_synced_through).to eq('2026-09-25T20:22:12Z')
    end
  end

  # rails-settings-ui derives each admin form field's type from the setting's
  # default; a nil default raises UnknownDefaultValueType on every "save all"
  # (ACCOUNTS-78T), taking the whole settings page down.
  it 'gives every admin-editable setting a typed (non-nil) default' do
    nil_defaults = RailsSettingsUi.default_settings.select { |_name, default| default.nil? }.keys

    expect(nil_defaults).to be_empty
  end
end
