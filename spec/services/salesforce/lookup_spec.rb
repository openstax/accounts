require 'rails_helper'

RSpec.describe Salesforce::Lookup do
  let(:user) { FactoryBot.create(:user) }
  let(:matching_lead) { Salesforce::Records::Lead.new(id: 'L1', accounts_uuid: user.uuid) }
  let(:foreign_lead) { Salesforce::Records::Lead.new(id: 'L2', accounts_uuid: 'OTHER') }

  before do
    allow(user).to receive(:best_email_address_for_salesforce).and_return('e@example.com')
  end

  describe '.lead_for' do
    context 'with a stored salesforce_lead_id that still owns the user' do
      it 'matches by stored_id' do
        user.update!(salesforce_lead_id: 'L1')
        allow(Salesforce::Records::Lead).to receive(:find).with('L1').and_return(matching_lead)
        result = described_class.lead_for(user)
        expect(result.lead).to eq(matching_lead)
        expect(result.matched_by).to eq(:stored_id)
      end
    end

    context 'when stored id belongs to another user' do
      it 'falls through to uuid match and records the disown' do
        user.update!(salesforce_lead_id: 'L2')
        allow(Salesforce::Records::Lead).to receive(:find).with('L2').and_return(foreign_lead)
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(matching_lead)
        result = described_class.lead_for(user)
        expect(result.lead).to eq(matching_lead)
        expect(result.matched_by).to eq(:uuid)
        expect(result.rejected).to include(:stored_id_owned_by_other_user)
        expect(SecurityLog.where(event_type: 'salesforce_lookup_stored_id_disowned', user: user)).to exist
      end
    end

    context 'when stored id raises (missing in SF)' do
      it 'falls through to uuid match' do
        user.update!(salesforce_lead_id: 'L_MISSING')
        allow(Salesforce::Records::Lead).to receive(:find).with('L_MISSING').and_raise(StandardError, 'gone')
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(matching_lead)
        result = described_class.lead_for(user)
        expect(result.matched_by).to eq(:uuid)
      end
    end

    context 'when only email matches but its UUID is foreign' do
      it 'rejects the email match' do
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(nil)
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ email: 'e@example.com' }).and_return(foreign_lead)
        result = described_class.lead_for(user)
        expect(result.lead).to be_nil
        expect(result.rejected).to include(:email_match_uuid_conflict)
      end
    end

    context 'when email matches and is adoptable (UUID blank)' do
      it 'matches by email' do
        adoptable = Salesforce::Records::Lead.new(id: 'L_OLD', accounts_uuid: nil)
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(nil)
        allow(Salesforce::Records::Lead).to receive(:find_by).with({ email: 'e@example.com' }).and_return(adoptable)
        result = described_class.lead_for(user)
        expect(result.lead).to eq(adoptable)
        expect(result.matched_by).to eq(:email)
      end
    end

    context 'when nothing matches' do
      it 'returns nil lead with matched_by nil' do
        allow(Salesforce::Records::Lead).to receive(:find_by).and_return(nil)
        result = described_class.lead_for(user)
        expect(result.lead).to be_nil
        expect(result.matched_by).to be_nil
      end
    end
  end

  describe '.contact_for' do
    it 'returns the stored Contact when it owns the user' do
      user.update!(salesforce_contact_id: 'C1')
      contact = Salesforce::Records::Contact.new(id: 'C1', accounts_uuid: user.uuid, master_record_id: nil, is_deleted: false)
      allow(Salesforce::Records::Contact).to receive(:find).with('C1').and_return(contact)
      expect(described_class.contact_for(user)).to eq(contact)
    end

    it 'falls through to UUID lookup when stored id is disowned' do
      user.update!(salesforce_contact_id: 'C_FOREIGN')
      foreign = Salesforce::Records::Contact.new(id: 'C_FOREIGN', accounts_uuid: 'OTHER', master_record_id: nil, is_deleted: false)
      uuid_match = Salesforce::Records::Contact.new(id: 'C_OK', accounts_uuid: user.uuid, master_record_id: nil, is_deleted: false)
      allow(Salesforce::Records::Contact).to receive(:find).with('C_FOREIGN').and_return(foreign)
      allow(Salesforce::Records::Contact).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(uuid_match)
      expect(described_class.contact_for(user)).to eq(uuid_match)
    end

    it 'returns nil when nothing owns the user' do
      allow(Salesforce::Records::Contact).to receive(:find_by).with({ accounts_uuid: user.uuid }).and_return(nil)
      expect(described_class.contact_for(user)).to be_nil
    end
  end
end
