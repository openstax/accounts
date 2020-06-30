require 'rails_helper'

module Newflow
  module EducatorSignup
    describe VerifyEmailByPin, type: :handler do
      context 'when success' do
        before { disable_sfdc_client }

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

        it 'activates their account' do
          expect_any_instance_of(ActivateAccount).to receive(:exec).with(hash_including(user: user))
          described_class.call(params: params, email_address: email)
        end

        it 'sets the user (email owner) state to "activated"' do
          expect(email.user.state).not_to eq('activated')
          described_class.call(params: params, email_address: email)
          expect(email.user.state).to eq('activated')
        end

        it 'marks the user\'s EmailAddress as verified' do
          expect(email.verified).to be(false)
          described_class.call(params: params, email_address: email)
          expect(email.verified).to be(true)
        end
      end
    end
  end
end
