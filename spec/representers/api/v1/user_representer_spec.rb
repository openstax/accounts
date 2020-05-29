require 'rails_helper'

RSpec.describe Api::V1::UserRepresenter, type: :representer do
  let(:user)            { FactoryBot.create :user  }
  subject(:representer) { described_class.new(user) }

  context 'uuid' do
    it 'can be read' do
      expect(representer.to_hash['uuid']).to eq user.uuid
    end

    it 'cannot be written (attempts are silently ignored)' do
      hash = { 'uuid' => SecureRandom.uuid }

      expect(user).not_to receive(:uuid=)
      expect { representer.from_hash(hash) }.not_to change { user.reload.uuid }
    end
  end

  context 'support_identifier' do
    it 'can be read' do
      expect(representer.to_hash['support_identifier']).to eq user.support_identifier
    end

    it 'cannot be written (attempts are silently ignored)' do
      hash = { 'support_identifier' => "cs_#{SecureRandom.hex(4)}" }

      expect(user).not_to receive(:support_identifier=)
      expect { representer.from_hash(hash) }.not_to change { user.reload.support_identifier }
    end
  end

  context 'is_test' do
    it 'can be read' do
      expect(representer.to_hash['is_test']).to eq user.is_test?
    end

    it 'cannot be written (attempts are silently ignored)' do
      hash = { 'is_test' => true }

      expect(user).not_to receive(:is_test=)
      expect { representer.from_hash(hash) }.not_to change { user.reload.is_test? }
    end
  end

  context 'is_not_gdpr_location' do
    it 'is not there normally' do
      expect(representer.to_hash).not_to have_key('is_not_gdpr_location')
    end

    it "is there when set and private data included" do
      user.is_not_gdpr_location = false
      expect(representer.to_hash(user_options: {include_private_data: true})['is_not_gdpr_location']).to eq false
    end
  end

  context 'school_type' do
    before { user.school_type = :home_school }

    it 'is not there normally' do
      expect(representer.to_hash).not_to have_key('school_type')
    end

    it 'is there when set and private data included' do
      expect(
        representer.to_hash(user_options: {include_private_data: true})['school_type']
      ).to eq 'home_school'
    end
  end

  context 'school_location' do
    before { user.school_location = :domestic_school }

    it 'is not there normally' do
      expect(representer.to_hash).not_to have_key('school_location')
    end

    it 'is there when set and private data included' do
      expect(
        representer.to_hash(user_options: {include_private_data: true})['school_location']
      ).to eq 'domestic_school'
    end
  end

  context 'is_kip' do
    it 'can be read' do
      expect(representer.to_hash['is_kip']).to eq user.is_kip
    end

    it 'cannot be written (attempts are silently ignored)' do
      hash = { 'is_kip' => true }

      expect(user).not_to receive(:is_kip=)
      expect { representer.from_hash(hash) }.not_to change { user.reload.is_kip }
    end
  end
end
