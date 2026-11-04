require 'rails_helper'

module Newflow
  describe ChangeSignupEmail, type: :handler do
    before do
      FactoryBot.create :email_address, value: before_change_email, verified: false, user: user
    end

    let(:user) { FactoryBot.create :user }

    let(:before_change_email) {  'original@example.com' }

    let(:params) {
      {
        change_signup_email: {
          email: Faker::Internet.email
        }
      }
    }

    context 'when success' do
      it 'changes the user\'s only email address' do
        new_email = params.dig(:change_signup_email, :email)

        expect(user.email_addresses.first.value).not_to eq new_email

        described_class.call(params: params, user: user)
        expect(user.email_addresses.first.value).to eq new_email
      end

      it 'does not create another email address record' do
        expect {
          described_class.call(params: params, user: user)
        }.not_to change(EmailAddress, :count)
      end

      it 'issues a new PIN for a new address' do
        expect {
          described_class.call(params: params, user: user)
        }.to change { user.email_addresses.first.confirmation_pin }
      end

      it 'keeps the PIN when the same address is entered again' do
        same = { change_signup_email: { email: before_change_email.upcase } }

        expect {
          described_class.call(params: same, user: user)
        }.not_to change { user.email_addresses.first.reload.confirmation_pin }
      end

      it 'sends an email to the new email address' do
        expect_any_instance_of(NewflowMailer).to(
          receive(:signup_email_confirmation).once.and_call_original
        )
        described_class.call(params: params, user: user)
        perform_enqueued_jobs
      end

      it 'enqueues the email at the signup-confirmation priority' do
        described_class.call(params: params, user: user)

        expect(enqueued_jobs.last['priority']).to eq SendSignupConfirmationEmail::PRIORITY
      end
    end

    context 'when the PIN attempts for the address are used up' do
      let(:email_address) { user.email_addresses.first }

      before do
        ConfirmByPin.max_pin_failures.times { ConfirmByPin.call(contact_info: email_address, pin: 'nope') }
      end

      def locked?
        result = ConfirmByPin.call(contact_info: email_address.reload, pin: email_address.confirmation_pin)
        result.errors.map(&:code) == [:no_pin_confirmation_attempts_remaining]
      end

      it 'stays locked after a case-only edit' do
        described_class.call(params: { change_signup_email: { email: before_change_email.upcase } }, user: user)
        expect(locked?).to be(true)
      end

      it 'stays locked after A, then B, then A in different case' do
        described_class.call(params: { change_signup_email: { email: 'other@example.com' } }, user: user)
        described_class.call(params: { change_signup_email: { email: 'Original@Example.com' } }, user: user)
        expect(locked?).to be(true)
      end
    end

    context 'when email address already taken' do
      # meaning when there's already a verified email address with the same value
      before do
        FactoryBot.create(
          :email_address,
          value: params.dig(:change_signup_email, :email),
          verified: true
        )
      end

      it 'adds errors to email input' do
        result = described_class.call(params: params, user: user)
        expect(result.errors).to have_offending_input(:email)
      end
    end
  end

end
