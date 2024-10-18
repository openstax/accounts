require 'rails_helper'

describe Api::V1::ExternalIdRepresenter, type: :representer do
  let(:external_id)     { FactoryBot.create :external_id }
  subject(:representer) { described_class.new external_id }

  context 'user_id' do
    it 'can be read' do
      expect(representer.to_hash['user_id']).to eq external_id.user_id
    end

    it 'can be written' do
      expect(external_id).to receive(:user_id=).and_call_original
      expect { representer.from_hash 'user_id' => 1000000 }.to(
        change { external_id.user_id }
      )
    end
  end

  context 'external_id' do
    it 'can be read' do
      expect(representer.to_hash['external_id']).to eq external_id.external_id
    end

    it 'can be written' do
      expect(external_id).to receive(:external_id=).and_call_original
      expect { representer.from_hash 'external_id' => SecureRandom.uuid }.to(
        change { external_id.external_id }
      )
    end
  end
end
