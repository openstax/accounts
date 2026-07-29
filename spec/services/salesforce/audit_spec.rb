require 'rails_helper'

RSpec.describe Salesforce::Audit do
  let(:user) { FactoryBot.create(:user) }

  describe '.record' do
    it 'prepends salesforce_ to the event name' do
      expect {
        described_class.record(user, :upsert_lead_saved, lead_id: 'X')
      }.to change { SecurityLog.where(event_type: 'salesforce_upsert_lead_saved').count }.by(1)
    end

    it 'stores details in event_data' do
      described_class.record(user, :upsert_lead_saved, lead_id: 'X', matched_by: :uuid)
      log = SecurityLog.where(event_type: 'salesforce_upsert_lead_saved').last
      expect(log.event_data).to include('lead_id' => 'X', 'matched_by' => 'uuid')
    end

    it 'raises if the event_type is not registered' do
      expect {
        described_class.record(user, :not_a_real_event)
      }.to raise_error(ArgumentError, /Unknown Salesforce audit event/)
    end

    it 'allows nil user (system-level events)' do
      expect {
        described_class.record(nil, :upsert_lead_saved, lead_id: 'X')
      }.not_to raise_error
    end
  end
end
