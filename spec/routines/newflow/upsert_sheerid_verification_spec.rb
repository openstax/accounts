require 'rails_helper'
require 'vcr_helper'

module Newflow
  RSpec.describe UpsertSheeridVerification, type: :routine, vcr: VCR_OPTS do
    context 'success' do
      subject(:result) { described_class.call(verification_id: verification_id) }
      let(:verification_id) { '5ef42cfaeddfdd1bd961c088' }

      context 'creates a new record' do
        example do
          expect { result }.to change(SheeridVerification, :count).by(1)
        end

        it 'stores the verification details' do
          expect(result.outputs.verification.verification_id).to eq(verification_id)
          expect(result.outputs.verification.email).to eq('bed1+bryan47dev@rice.edu')
          expect(result.outputs.verification.current_step).to eq(SheeridVerification::VERIFIED)
          expect(result.outputs.verification.first_name).to eq('Bryan47dev')
          expect(result.outputs.verification.last_name).to eq('Dimas')
          expect(result.outputs.verification.organization_name).to eq('Rice University (Houston, TX)')
        end
      end

      it 'outputs the new verification' do
        expect(result.outputs.verification).to be_present
      end
    end
  end
end
