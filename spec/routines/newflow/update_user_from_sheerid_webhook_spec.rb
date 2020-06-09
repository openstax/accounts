require 'rails_helper'
require 'vcr_helper'

module Newflow
  RSpec.describe UpdateUserFromSheeridWebhook, type: :routine, vcr: VCR_OPTS  do
    context 'when success' do
      subject(:run) { described_class.call(verification_id: verification_id) }

      let!(:educator) do
        user = create_newflow_user(email)
        user.update!(sheerid_verification_id: verification_id)
        user
      end

      let(:verification_id) { '5ecfdd5a7ccdbc1a94865309' }
      let(:email) { 'asldkfjaklsdjf@gmail.com' }

      it 'confirms their faculty status' do
        expect(educator.confirmed_faculty?).to be_falsey
        run
        educator.reload
        expect(educator.confirmed_faculty?).to be_truthy
      end

      it 'creates a security log' do
        expect { run }.to change(SecurityLog, :count).by(1)
      end

      it 'updates their first name' do
        previous_first_name = Faker::Name.unique.first_name
        educator.update!(first_name: previous_first_name)
        run
        expect(educator.reload.first_name).not_to eq(previous_first_name)
      end

      it 'updates their last name' do
        previous_last_name = Faker::Name.unique.last_name
        educator.update!(last_name: previous_last_name)
        run
        expect(educator.reload.last_name).not_to eq(previous_last_name)
      end

      it 'updates sheerid_reported_school' do
        expect(educator.sheerid_reported_school).to be_blank
        run
        expect(educator.reload.sheerid_reported_school).not_to be_blank
      end

      context 'when there is a mismatch on the email' do
        before do
          # this causes a mismatch beacause the actual verirication id (which we get from SheerID's API)
          # will be different from what we have stored for the user with the given email address.
          educator.update!(sheerid_verification_id: Faker::Alphanumeric.alphanumeric(number: 10))
        end

        it 'adds errors' do
          expect(run.errors.any?).to be_truthy
        end

        it 'adds errors, does not raise error' do
          expect {
            run
          }.not_to(
            raise_error
          )
        end

        it 'calls Raven' do
          expect(Raven).to receive(:capture_message).with('verification id and email mismatch', any_args)
          run
        end
      end
    end
  end
end
