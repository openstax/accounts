require 'rails_helper'

RSpec.describe Api::V1::FindUserRepresenter, type: :representer do
  let(:payload)         { Hashie::Mash.new }
  subject(:representer) { described_class.new payload }

  context 'id' do
    it 'can be read' do
      payload.id = 123
      expect(representer.to_hash['id']).to eq payload.id
    end

    it 'cannot be written (attempts are silently ignored)' do
      hash = { 'id' => 456 }

      expect(payload).not_to receive(:id=)
      expect { representer.from_hash(hash) }.not_to change { payload.id }
    end
  end

  context 'uuid' do
    it 'can be read' do
      payload.uuid = SecureRandom.uuid
      expect(representer.to_hash['uuid']).to eq payload.uuid
    end

    it 'cannot be written (attempts are silently ignored)' do
      hash = { 'uuid' => SecureRandom.uuid }

      expect(payload).not_to receive(:uuid=)
      expect { representer.from_hash(hash) }.not_to change { payload.uuid }
    end
  end

  context 'support_identifier' do
    it 'can be read' do
      payload.support_identifier = SecureRandom.uuid
      expect(representer.to_hash['support_identifier']).to eq payload.support_identifier
    end

    it 'cannot be written (attempts are silently ignored)' do
      hash = { 'support_identifier' => SecureRandom.uuid }

      expect(payload).not_to receive(:support_identifier=)
      expect { representer.from_hash(hash) }.not_to change { payload.support_identifier }
    end
  end

  context 'external_id' do
    it 'cannot be read' do
      payload.external_id = SecureRandom.uuid
      expect(representer.to_hash['external_id']).to be_nil
    end

    it 'can be written' do
      expect(payload).to receive(:external_id=).and_call_original
      expect { representer.from_hash 'external_id' => SecureRandom.uuid }.to(
        change { payload.external_id }
      )
    end
  end

  context 'is_test' do
    it 'can be read' do
      payload.is_test = true
      expect(representer.to_hash['is_test']).to eq payload.is_test
    end

    it 'cannot be written (attempts are silently ignored)' do
      hash = { 'is_test' => false }

      expect(payload).not_to receive(:is_test=)
      expect { representer.from_hash(hash) }.not_to change { payload.is_test }
    end
  end

  context 'sso' do
    it 'can be read' do
      expect(representer.to_hash(user_options: { sso: '123' })['sso']).to eq '123'
    end

    it 'can be written' do
      hash = { 'sso' => '456' }

      expect(payload).to receive(:sso=).and_call_original
      expect { representer.from_hash(hash) }.to change { payload.sso }
    end
  end
end
