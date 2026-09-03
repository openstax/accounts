require 'rails_helper'

module Newflow
  describe UpdateExistingSalesforceLead, type: :routine do
    let(:user) { FactoryBot.create(:user, role: User::STUDENT_ROLE, salesforce_lead_id: 'SF_LEAD_123') }
    let(:lead) { OpenStax::Salesforce::Remote::Lead.new(email: 'someone@example.com') }

    before do
      stub_sentry
      allow(lead).to receive(:id).and_return('SF_LEAD_123')
    end

    it 'hands the existing lead to CreateOrUpdateSalesforceLead so the role is corrected' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with('SF_LEAD_123').and_return(lead)
      expect_any_instance_of(CreateOrUpdateSalesforceLead).to receive(:exec) do |routine, **kwargs|
        expect(kwargs[:user]).to eq(user)
        routine.send(:outputs).lead_saved = true
      end

      described_class.call(user: user)

      expect(user.reload.salesforce_lead_id).to eq('SF_LEAD_123')
      expect(SecurityLog.where(event_type: :updated_salesforce_lead_after_role_switch).count).to eq(1)
    end

    it 'adopts a lead found by uuid when the stored id is stale' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with('SF_LEAD_123').and_raise(StandardError)
      allow(lead).to receive(:id).and_return('SF_LEAD_FROM_UUID')
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(accounts_uuid: user.uuid).and_return(lead)
      allow_any_instance_of(CreateOrUpdateSalesforceLead).to receive(:exec) { |r, **_| r.send(:outputs).lead_saved = true }

      described_class.call(user: user)

      expect(user.reload.salesforce_lead_id).to eq('SF_LEAD_FROM_UUID')
    end

    it 'never creates a lead when the user has none' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with('SF_LEAD_123').and_raise(StandardError)
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_return(nil)
      expect_any_instance_of(CreateOrUpdateSalesforceLead).not_to receive(:exec)

      described_class.call(user: user)

      expect(user.reload.salesforce_lead_id).to be_nil
      expect(SecurityLog.where(event_type: :no_salesforce_lead_to_update).count).to eq(1)
    end

    it 'raises on a salesforce outage rather than discarding a known lead id' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with('SF_LEAD_123').and_raise(StandardError)
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_raise(StandardError, 'timeout')
      expect_any_instance_of(CreateOrUpdateSalesforceLead).not_to receive(:exec)

      expect(Sentry).to receive(:capture_message).with(/lead lookup failed/)

      expect { described_class.call(user: user) }.to raise_error(StandardError, 'timeout')

      expect(user.reload.salesforce_lead_id).to eq('SF_LEAD_123')
    end

    it 'does not claim success when salesforce rejects the write' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with('SF_LEAD_123').and_return(lead)
      allow_any_instance_of(CreateOrUpdateSalesforceLead).to receive(:exec) { |r, **_| r.send(:outputs).lead_saved = false }

      described_class.call(user: user)

      expect(SecurityLog.where(event_type: :updated_salesforce_lead_after_role_switch).count).to eq(0)
    end
  end
end
