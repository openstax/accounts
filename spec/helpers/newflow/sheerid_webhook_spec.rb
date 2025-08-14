require 'rails_helper'

RSpec.describe Newflow::EducatorSignup::SheeridWebhook, type: :routine do
  let(:verification_id) { 'test_verification_id' }
  let(:details) { double('details', success?: true, email: 'test@example.com', current_step: 'success', first_name: 'John', last_name: 'Doe', organization_name: 'Test School') }
  let(:user) { create_newflow_user('test@example.com', 'password', terms_agreed: true, role: 'instructor') }
  let(:verification) { create(:sheerid_verification, verification_id: verification_id, email: 'test@example.com') }

  before do
    allow(SheeridAPI).to receive(:get_verification_details).with(verification_id).and_return(details)
    allow(EmailAddress).to receive_message_chain(:verified, :find_by).with(value: 'test@example.com').and_return(user)
  end

  describe '#fetch_verification_details' do
    context 'when the API call is successful' do
      it 'returns the verification details' do
        result = subject.send(:fetch_verification_details, verification_id)
        expect(result).to eq(details)
      end
    end

    context 'when the API call fails' do
      let(:details) { double('details', success?: false) }

      before do
        allow(subject).to receive(:fatal_error).and_return(nil)
      end

      it 'logs an error and returns nil' do
        expect(Sentry).to receive(:capture_message).with(
          "[SheerID Webhook] fetching verification details FAILED",
          extra: { verification_id: verification_id, verification_details: details }
        )
        result = subject.send(:fetch_verification_details, verification_id)
        expect(result).to be_nil
      end
    end
  end
end