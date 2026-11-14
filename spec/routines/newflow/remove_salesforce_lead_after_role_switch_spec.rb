require 'rails_helper'

module Newflow
  describe RemoveSalesforceLeadAfterRoleSwitch, type: :routine do
    let(:lead_id) { '00QPc00000ythJVMAY' }
    let(:user) { FactoryBot.create(:user, role: User::STUDENT_ROLE, salesforce_lead_id: lead_id) }
    let(:lead) { OpenStax::Salesforce::Remote::Lead.new(email: 'someone@example.com') }
    let(:sfdc_client) { double('sfdc_client') }

    before do
      stub_sentry
      allow(lead).to receive(:id).and_return(lead_id)
      allow(ActiveForce).to receive(:sfdc_client).and_return(sfdc_client)
    end

    def lead_created_at(time, id: lead_id)
      allow(sfdc_client).to receive(:query)
        .with("SELECT CreatedDate FROM Lead WHERE Id = '#{id}'")
        .and_return([{ 'CreatedDate' => time.utc.strftime('%Y-%m-%dT%H:%M:%S.000+0000') }])
    end

    def stored_lead_found
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with(lead_id).and_return(lead)
    end

    context 'when the educator signup created the lead' do
      before do
        stored_lead_found
        lead_created_at(user.created_at + 5.minutes)
      end

      it 'deletes it and unlinks the user' do
        expect(lead).to receive(:destroy)
        expect_any_instance_of(CreateOrUpdateSalesforceLead).not_to receive(:exec)

        described_class.call(user: user)

        expect(user.reload.salesforce_lead_id).to be_nil
        log = SecurityLog.find_by(event_type: :deleted_salesforce_lead_after_role_switch)
        expect(log.event_data['lead_id']).to eq(lead_id)
        expect(SecurityLog.where(event_type: :updated_salesforce_lead_after_role_switch).count).to eq(0)
      end

      it 'keeps the link and swallows the failure when the delete fails' do
        allow(lead).to receive(:destroy).and_raise(StandardError, 'boom')
        expect(Sentry).to receive(:capture_message).with(/lead delete failed/)

        expect { described_class.call(user: user) }.not_to raise_error

        expect(user.reload.salesforce_lead_id).to eq(lead_id)
        expect(SecurityLog.where(event_type: :deleted_salesforce_lead_after_role_switch).count).to eq(0)
      end

      it 'raises for retry when the delete fails in a delayed job' do
        allow(Delayed::Worker).to receive(:delay_jobs).and_return(true)
        allow(lead).to receive(:destroy).and_raise(StandardError, 'boom')
        expect(Sentry).to receive(:capture_message).with(/lead delete failed/)

        expect {
          described_class.call(user: user)
        }.to raise_error(StandardError, /Salesforce lead delete failed for user #{user.id}/)

        expect(user.reload.salesforce_lead_id).to eq(lead_id)
      end
    end

    context 'when the lead existed before the signup' do
      before do
        stored_lead_found
        lead_created_at(user.created_at - 30.days)
      end

      it 'relabels it Student instead of deleting it' do
        expect(lead).not_to receive(:destroy)
        expect_any_instance_of(CreateOrUpdateSalesforceLead).to receive(:exec) do |routine, **kwargs|
          expect(kwargs[:user]).to eq(user)
          routine.send(:outputs).lead_saved = true
        end

        described_class.call(user: user)

        expect(user.reload.salesforce_lead_id).to eq(lead_id)
        expect(SecurityLog.where(event_type: :updated_salesforce_lead_after_role_switch).count).to eq(1)
      end

      it 'swallows a failure while pushing the lead' do
        allow_any_instance_of(CreateOrUpdateSalesforceLead).to receive(:exec).and_raise(StandardError, 'boom')
        expect(Sentry).to receive(:capture_message).with(/lead update failed/)

        expect { described_class.call(user: user) }.not_to raise_error

        expect(SecurityLog.where(event_type: :updated_salesforce_lead_after_role_switch).count).to eq(0)
      end

      it 'raises for retry when lead update blows up in a delayed job' do
        allow(Delayed::Worker).to receive(:delay_jobs).and_return(true)
        allow_any_instance_of(CreateOrUpdateSalesforceLead).to receive(:exec).and_raise(StandardError, 'boom')
        expect(Sentry).to receive(:capture_message).with(/lead update failed/)

        expect {
          described_class.call(user: user)
        }.to raise_error(StandardError, /Salesforce lead update failed for user #{user.id}/)

        expect(SecurityLog.where(event_type: :updated_salesforce_lead_after_role_switch).count).to eq(0)
      end

      it 'does not claim success when salesforce rejects the write' do
        allow_any_instance_of(CreateOrUpdateSalesforceLead).to receive(:exec) { |r, **_| r.send(:outputs).lead_saved = false }

        described_class.call(user: user)

        expect(SecurityLog.where(event_type: :updated_salesforce_lead_after_role_switch).count).to eq(0)
      end

      it 'raises for retry when salesforce rejects the write in a delayed job' do
        allow(Delayed::Worker).to receive(:delay_jobs).and_return(true)
        allow_any_instance_of(CreateOrUpdateSalesforceLead).to receive(:exec) { |r, **_| r.send(:outputs).lead_saved = false }

        expect {
          described_class.call(user: user)
        }.to raise_error(StandardError, /Salesforce lead update failed for user #{user.id}/)

        expect(SecurityLog.where(event_type: :updated_salesforce_lead_after_role_switch).count).to eq(0)
      end
    end

    it 'relabels a converted lead through its Contact without deleting anything' do
      stored_lead_found
      allow(lead).to receive(:is_converted).and_return(true)
      expect(sfdc_client).not_to receive(:query)
      expect(lead).not_to receive(:destroy)
      expect_any_instance_of(CreateOrUpdateSalesforceLead).to receive(:exec) do |routine, **_|
        routine.send(:outputs).lead_saved = false
        routine.send(:outputs).contact_saved = true
      end

      described_class.call(user: user)

      expect(SecurityLog.where(event_type: :updated_salesforce_lead_after_role_switch).count).to eq(1)
    end

    it 'adopts a lead found by uuid when the stored id is stale' do
      uuid_lead_id = '00QPc00000yuvu3MAA'
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with(lead_id).and_raise(StandardError)
      allow(lead).to receive(:id).and_return(uuid_lead_id)
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).with(accounts_uuid: user.uuid).and_return(lead)
      lead_created_at(user.created_at - 30.days, id: uuid_lead_id)
      allow_any_instance_of(CreateOrUpdateSalesforceLead).to receive(:exec) { |r, **_| r.send(:outputs).lead_saved = true }

      described_class.call(user: user)

      expect(user.reload.salesforce_lead_id).to eq(uuid_lead_id)
    end

    it 'changes nothing when the created date cannot be read' do
      stored_lead_found
      allow(sfdc_client).to receive(:query).and_raise(StandardError, 'timeout')
      expect(lead).not_to receive(:destroy)
      expect_any_instance_of(CreateOrUpdateSalesforceLead).not_to receive(:exec)
      expect(Sentry).to receive(:capture_message).with(/lead created date lookup failed/)

      expect { described_class.call(user: user) }.not_to raise_error

      expect(user.reload.salesforce_lead_id).to eq(lead_id)
    end

    it 'raises for retry when the created date cannot be read in a delayed job' do
      allow(Delayed::Worker).to receive(:delay_jobs).and_return(true)
      stored_lead_found
      allow(sfdc_client).to receive(:query).and_raise(StandardError, 'timeout')
      expect(Sentry).to receive(:capture_message).with(/lead created date lookup failed/)

      expect {
        described_class.call(user: user)
      }.to raise_error(StandardError, /Salesforce lead created date lookup failed for user #{user.id}/)
    end

    # ActiveForce's `find` is a SOQL query, so genuine absence is a nil return, not
    # a raise. Simulating it with `and_raise` would be testing the outage path.
    it 'never creates a lead when the user has none' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with(lead_id).and_return(nil)
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_return(nil)
      expect_any_instance_of(CreateOrUpdateSalesforceLead).not_to receive(:exec)

      described_class.call(user: user)

      expect(user.reload.salesforce_lead_id).to be_nil
      expect(SecurityLog.where(event_type: :no_salesforce_lead_to_update).count).to eq(1)
    end

    it 'keeps a known lead id when the stored-id lookup fails and nothing else matches' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with(lead_id).and_raise(StandardError)
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_return(nil)
      expect_any_instance_of(CreateOrUpdateSalesforceLead).not_to receive(:exec)
      expect(Sentry).to receive(:capture_message).with(/lead lookup by stored id failed/)

      described_class.call(user: user)

      expect(user.reload.salesforce_lead_id).to eq(lead_id)
      expect(SecurityLog.where(event_type: :no_salesforce_lead_to_update).count).to eq(0)
    end

    it 'keeps a known lead id when salesforce cannot be reached' do
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with(lead_id).and_raise(StandardError)
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_raise(StandardError, 'timeout')
      expect_any_instance_of(CreateOrUpdateSalesforceLead).not_to receive(:exec)
      expect(Sentry).to receive(:capture_message).with(/lead lookup failed/)

      expect { described_class.call(user: user) }.not_to raise_error

      expect(user.reload.salesforce_lead_id).to eq(lead_id)
      expect(SecurityLog.where(event_type: :no_salesforce_lead_to_update).count).to eq(0)
    end

    it 'raises for retry when salesforce cannot be reached in a delayed job' do
      allow(Delayed::Worker).to receive(:delay_jobs).and_return(true)
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find).with(lead_id).and_raise(StandardError)
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_raise(StandardError, 'timeout')
      expect_any_instance_of(CreateOrUpdateSalesforceLead).not_to receive(:exec)
      expect(Sentry).to receive(:capture_message).with(/lead lookup failed/)

      expect {
        described_class.call(user: user)
      }.to raise_error(StandardError, /Salesforce lead lookup failed for user #{user.id}/)

      expect(user.reload.salesforce_lead_id).to eq(lead_id)
    end
  end
end
