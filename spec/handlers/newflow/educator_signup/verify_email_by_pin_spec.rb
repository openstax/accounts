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
          expect_any_instance_of(ActivateEducator).to receive(:exec).with(hash_including(user: user))
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

        it 'accepts a PIN typed with spaces or pasted with surrounding text' do
          pin = email.confirmation_pin
          spaced = { confirm: { pin: " PIN: #{pin[0, 3]} #{pin[3..]} " } }

          result = described_class.call(params: spaced, email_address: email)

          expect(result.errors).to be_empty
          expect(email.reload.verified).to be(true)
        end
      end

      context 'when failure' do
        before { disable_sfdc_client }

        let(:user) { FactoryBot.create(:user, state: 'unverified') }
        let(:email) { FactoryBot.create(:email_address, user: user) }

        it 'reports an incorrect PIN as incorrect' do
          result = described_class.call(params: { confirm: { pin: 'nope' } }, email_address: email)

          expect(result.errors.map(&:code)).to eq [:invalid_confirmation_pin]
          expect(result.errors.first.message).to eq I18n.t(:"login_signup_form.pin_not_correct")
        end

        it 'counts each wrong PIN exactly once' do
          2.times do
            described_class.call(params: { confirm: { pin: 'nope' } }, email_address: email)
          end

          expect(ConfirmByPin.sequential_failure_for(email).length).to eq 2
        end

        it 'says the attempts are used up, not that the PIN is wrong, once locked out' do
          ConfirmByPin.max_pin_failures.times do
            described_class.call(params: { confirm: { pin: 'nope' } }, email_address: email)
          end

          result = described_class.call(
            params: { confirm: { pin: email.confirmation_pin } }, email_address: email
          )

          expect(result.errors.map(&:code)).to eq [:no_pin_confirmation_attempts_remaining]
          expect(result.errors.first.message).to eq I18n.t(:"login_signup_form.pin_attempts_exhausted")
          expect(email.reload.verified).to be(false)
        end
      end
    end
  end
end
