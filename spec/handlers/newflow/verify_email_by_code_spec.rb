require 'rails_helper'

module Newflow
  describe VerifyEmailByCode, type: :handler do
    context 'when success' do
      let(:params) do
        { code: email.confirmation_code }
      end

      let(:email) do
        FactoryBot.create(:email_address, user: user)
      end

      let(:user) do
        FactoryBot.create(:user, state: 'unverified')
      end

      it 'verifies the email address found by the given code' do
        expect(email.verified).to be(false)
        described_class.call(params: params)
        email.reload
        expect(email.verified).to be(true)
      end

      it 'activates the user' do
        expect_any_instance_of(ActivateUser).to receive(:call).and_call_original
        described_class.call(params: params)
        user.reload
        expect(user.state).to eq('activated')
      end

      it 'outputs the user' do
        result = described_class.call(params: params)
        expect(result.outputs.user).to eq(user)
      end
    end

    context 'when failure' do
      # TODO
    end
  end
end
