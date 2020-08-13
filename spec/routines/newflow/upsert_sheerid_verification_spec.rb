require 'rails_helper'
require 'vcr_helper'

module Newflow
  module EducatorSignup

    describe UpsertSheeridVerification, type: :routine, vcr: VCR_OPTS do
      context 'success' do
        context 'when no SheeridVerification with that ID exists yet' do
          subject(:result) { described_class.call(verification_id: verification_id, details: verification_details) }

          let(:verification_id) { '5ef42cfaeddfdd1bd961c088' }
          let(:verification_details) {
            double(
              verification_id: verification_id,
              email: email,
              current_step: current_step,
              first_name: first_name,
              last_name: last_name,
              organization_name: organization_name
            )
          }
          let(:email) { 'bed1+bryan47dev@rice.edu' }
          let(:first_name) { 'Bryan47dev' }
          let(:last_name) { 'Dimas' }
          let(:organization_name) { 'Rice University (Houston, TX)' }
          let(:current_step) { SheeridVerification::VERIFIED }

          context 'creates a new record' do
            example do
              expect { result }.to change(SheeridVerification, :count).by(1)
            end

            it 'stores the verification details' do
              expect(result.outputs.verification.verification_id).to eq(verification_id)
              expect(result.outputs.verification.email).to eq(email)
              expect(result.outputs.verification.current_step).to eq(SheeridVerification::VERIFIED)
              expect(result.outputs.verification.first_name).to eq(first_name)
              expect(result.outputs.verification.last_name).to eq(last_name)
              expect(result.outputs.verification.organization_name).to eq(organization_name)
            end
          end

          it 'outputs the new verification' do
            expect(result.outputs.verification).to be_present
          end
        end

        context 'when a SheeridVerification with that ID already exists' do
          let!(:verification_details) do
            FactoryBot.create(:sheerid_verification,
              verification_id: verification_id,
              email: email,
              current_step: current_step,
              first_name: first_name,
              last_name: last_name,
              organization_name: organization_name
            )
          end

          subject(:result) { described_class.call(verification_id: verification_id, details: verification_details) }

          let(:verification_id) { '5ef42cfaeddfdd1bd961c088' }
          let(:email) { 'bed1+bryan47dev@rice.edu' }
          let(:first_name) { 'Bryan47dev' }
          let(:last_name) { 'Dimas' }
          let(:organization_name) { 'Rice University (Houston, TX)' }
          let(:current_step) { SheeridVerification::VERIFIED }

          context 'does not create a new record' do
            example do
              expect { result }.to change(SheeridVerification, :count).by(0)
            end
          end
        end
      end
    end

  end
end
