require 'rails_helper'

module Newflow
  describe DeleteSalesforceLead, type: :routine do
    let(:user) { FactoryBot.create(:user, salesforce_lead_id: 'SF_LEAD_123') }
    let(:lead) { OpenStax::Salesforce::Remote::Lead.new(email: 'someone@example.com') }

    before do
      stub_sentry
      allow(lead).to receive(:id).and_return('SF_LEAD_123')
    end

    it 'destroys the lead and forgets its id' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with('SF_LEAD_123').and_return(lead)
      expect(lead).to receive(:destroy).and_return(true)

      described_class.call(user: user)

      expect(user.reload.salesforce_lead_id).to be_nil
      expect(SecurityLog.where(event_type: :deleted_salesforce_lead).count).to eq(1)
    end

    it 'falls back to the uuid lookup when the stored id is stale' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with('SF_LEAD_123').and_raise(StandardError)
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(accounts_uuid: user.uuid).and_return(lead)
      expect(lead).to receive(:destroy).and_return(true)

      described_class.call(user: user)

      expect(user.reload.salesforce_lead_id).to be_nil
    end

    it 'clears the id when no lead exists to delete' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with('SF_LEAD_123').and_raise(StandardError)
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_return(nil)

      described_class.call(user: user)

      expect(user.reload.salesforce_lead_id).to be_nil
      expect(SecurityLog.where(event_type: :salesforce_lead_not_found_for_deletion).count).to eq(1)
    end

    it 'keeps the id when salesforce rejects the delete' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with('SF_LEAD_123').and_return(lead)
      allow(lead).to receive(:destroy).and_raise(StandardError, 'ENTITY_IS_DELETED')

      described_class.call(user: user)

      expect(user.reload.salesforce_lead_id).to eq('SF_LEAD_123')
      expect(SecurityLog.where(event_type: :salesforce_lead_delete_failed).count).to eq(1)
    end
  end
end
