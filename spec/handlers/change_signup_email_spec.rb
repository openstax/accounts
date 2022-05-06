require 'rails_helper'

RSpec.describe ChangeSignupEmail, type: :handler do
  before do
    FactoryBot.create :email_address, value: before_change_email, verified: false, user: user
  end

  let(:user) { FactoryBot.create :user }

  let(:before_change_email) {  'original@example.com' }

  let(:params) {
    {
      change_signup_email: {
        email: Faker::Internet.free_email
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

    it 'sends an email to the new email address' do
      expect_any_instance_of(SignupPasswordMailer).to(
        receive(:signup_email_confirmation).once.and_call_original
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
