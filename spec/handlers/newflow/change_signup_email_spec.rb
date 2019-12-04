require 'rails_helper'

module Newflow
  RSpec.describe ChangeSignupEmail, type: :handler do
    let(:user) { FactoryBot.create :user }
    let(:before_change_email) {  'original@example.com' }

    let(:params) {
      {
        change_signup_email: {
          email: Faker::Internet.free_email
        }
      }
    }

    before do
      FactoryBot.create :email_address, value: before_change_email, verified: false, user: user
    end

    context 'when success' do
      it 'changes the user\'s only email address' do
        new_email = params.dig(:change_signup_email, :email)

        described_class.call(params: params, user: user)
        expect(user.email_addresses.first.value).to eq new_email
      end

      it 'changes the PreAuthState\'s email address' do
        new_email = params.dig(:change_signup_email, :email)

        described_class.call(params: params, user: user)
        expect(new_email).not_to eq before_change_email
      end

      it 'deletes the previous email address, creates a new one' do
        expect {
          described_class.call(params: params, user: user)
        }.not_to change(EmailAddress, :count)
      end

      it 'updates the PreAuthState\'s contact_info_value' do
        new_email = params.dig(:change_signup_email, :email)

        described_class.call(params: params, user: user)
        user.reload
        expect(user.email_addresses.first.value).to eq new_email
      end

      it 'sends an email to the new email address' do
        expect_any_instance_of(NewflowMailer).to(
          receive(:signup_email_confirmation).and_call_original
        )
        described_class.call(params: params, user: user)
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
