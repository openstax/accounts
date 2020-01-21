require 'rails_helper'

module Newflow
  describe VerifyEmailByPin, type: :handler do
    context 'when success' do
      let(:user) do
        FactoryBot.create(:user, state: 'unverified', source_application: source_app, receive_newsletter: true)
      end

      let(:source_app) do
        FactoryBot.create(:doorkeeper_application)
      end

      let(:email) do
        FactoryBot.create(:email_address, user: user)
      end

      let(:params) do
        {
          confirm: {
            pin: email.confirmation_pin
          }
        }
      end

      it 'runs ActivateUser' do
        expect_any_instance_of(ActivateUser).to receive(:call).and_call_original
        described_class.call(params: params, email_address: email)
      end

      it 'sets the user (email owner) state to "activated"' do
        expect(email.user.state).not_to eq('activated')
        described_class.call(params: params, email_address: email)
        expect(email.user.state).to eq('activated')
      end

      context 'salesforce' do
        before do
          disable_sfdc_client
          allow(Settings::Salesforce).to receive(:push_leads_enabled).and_return(true)
        end

        it 'pushes the (user) lead up to Salesforce when push_leads_enabled' do
          expect_any_instance_of(PushSalesforceLead).to receive(:exec)
          described_class.call(params: params, email_address: email)
        end

        it 'signs up user for the newsletter when checked' do
          expect_any_instance_of(PushSalesforceLead).to(
            receive(:exec).with(hash_including(newsletter: true))
          )
          described_class.call(params: params, email_address: email)
        end
      end

      it 'marks the user-s EmailAddress as verified' do
        expect(email.verified).to be(false)
        described_class.call(params: params, email_address: email)
        expect(email.verified).to be(true)
      end
    end
  end
end
