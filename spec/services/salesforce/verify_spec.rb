require 'rails_helper'

RSpec.describe Salesforce::Verify do
  let(:user) { instance_double(User, uuid: 'USER-UUID') }

  describe '.lead_owns_user?' do
    it 'true when lead UUID matches' do
      lead = Salesforce::Records::Lead.new(accounts_uuid: 'USER-UUID')
      expect(described_class.lead_owns_user?(lead, user)).to be(true)
    end

    it 'true when lead UUID blank (adoptable)' do
      lead = Salesforce::Records::Lead.new(accounts_uuid: nil)
      expect(described_class.lead_owns_user?(lead, user)).to be(true)
    end

    it 'false when lead UUID belongs to someone else' do
      lead = Salesforce::Records::Lead.new(accounts_uuid: 'OTHER-UUID')
      expect(described_class.lead_owns_user?(lead, user)).to be(false)
    end

    it 'false for nil lead' do
      expect(described_class.lead_owns_user?(nil, user)).to be(false)
    end
  end

  describe '.contact_owns_user?' do
    it 'true when contact UUID matches and contact is live' do
      contact = Salesforce::Records::Contact.new(accounts_uuid: 'USER-UUID', master_record_id: nil, is_deleted: false)
      expect(described_class.contact_owns_user?(contact, user)).to be(true)
    end

    it 'false if contact has been merged' do
      contact = Salesforce::Records::Contact.new(accounts_uuid: 'USER-UUID', master_record_id: 'SOMETHING')
      expect(described_class.contact_owns_user?(contact, user)).to be(false)
    end

    it 'false if contact is deleted' do
      contact = Salesforce::Records::Contact.new(accounts_uuid: 'USER-UUID', is_deleted: true)
      expect(described_class.contact_owns_user?(contact, user)).to be(false)
    end

    it 'false when UUID mismatches' do
      contact = Salesforce::Records::Contact.new(accounts_uuid: 'OTHER', master_record_id: nil, is_deleted: false)
      expect(described_class.contact_owns_user?(contact, user)).to be(false)
    end

    it 'false when UUID is blank' do
      contact = Salesforce::Records::Contact.new(accounts_uuid: nil, master_record_id: nil, is_deleted: false)
      expect(described_class.contact_owns_user?(contact, user)).to be(false)
    end
  end

  describe '.contact_can_be_replaced?' do
    let(:replacement) do
      Salesforce::Records::Contact.new(id: 'NEW', accounts_uuid: 'USER-UUID', master_record_id: nil, is_deleted: false)
    end

    it ':gone when previous missing in SF' do
      allow(Salesforce::Records::Contact).to receive(:find_by).with({ id: 'OLD' }).and_return(nil)
      expect(described_class.contact_can_be_replaced?(previous_id: 'OLD', by: replacement, user: user)).to eq(:gone)
    end

    it ':gone when previous is_deleted' do
      prev = Salesforce::Records::Contact.new(id: 'OLD', is_deleted: true)
      allow(Salesforce::Records::Contact).to receive(:find_by).with({ id: 'OLD' }).and_return(prev)
      expect(described_class.contact_can_be_replaced?(previous_id: 'OLD', by: replacement, user: user)).to eq(:gone)
    end

    it ':merged when previous master_record_id == replacement id' do
      prev = Salesforce::Records::Contact.new(id: 'OLD', master_record_id: 'NEW', accounts_uuid: 'USER-UUID', is_deleted: false)
      allow(Salesforce::Records::Contact).to receive(:find_by).with({ id: 'OLD' }).and_return(prev)
      expect(described_class.contact_can_be_replaced?(previous_id: 'OLD', by: replacement, user: user)).to eq(:merged)
    end

    it ':uuid_cleared when previous accounts_uuid is now blank and new owns this user' do
      prev = Salesforce::Records::Contact.new(id: 'OLD', master_record_id: nil, accounts_uuid: nil, is_deleted: false)
      allow(Salesforce::Records::Contact).to receive(:find_by).with({ id: 'OLD' }).and_return(prev)
      expect(described_class.contact_can_be_replaced?(previous_id: 'OLD', by: replacement, user: user)).to eq(:uuid_cleared)
    end

    it 'false when both are live and own this user' do
      prev = Salesforce::Records::Contact.new(id: 'OLD', master_record_id: nil, accounts_uuid: 'USER-UUID', is_deleted: false)
      allow(Salesforce::Records::Contact).to receive(:find_by).with({ id: 'OLD' }).and_return(prev)
      expect(described_class.contact_can_be_replaced?(previous_id: 'OLD', by: replacement, user: user)).to be(false)
    end
  end
end
