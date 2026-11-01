require 'rails_helper'

module Newflow
  describe ResendSignupEmail, type: :routine do
    let(:user) { FactoryBot.create(:user, state: 'unverified') }
    let(:email) { FactoryBot.create(:email_address, user: user, verified: false) }

    it 'sends the confirmation email again with the same PIN' do
      pin = email.confirmation_pin

      expect {
        described_class.call(email_address: email)
      }.to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)

      expect(email.reload.confirmation_pin).to eq pin
      expect(email.confirmation_sent_at).to be_within(5.seconds).of(Time.current)
    end

    it 'refuses a second send within a minute' do
      email.update_column(:confirmation_sent_at, 30.seconds.ago)

      result = nil
      expect {
        result = described_class.call(email_address: email)
      }.not_to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)

      expect(result.errors.map(&:code)).to eq [:resent_too_soon]
    end

    it 'sends again once the minute has passed' do
      email.update_column(:confirmation_sent_at, 2.minutes.ago)

      expect {
        described_class.call(email_address: email)
      }.to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)
    end

    it 'does nothing for a verified address' do
      email.update_column(:verified, true)

      result = described_class.call(email_address: email)

      expect(result.errors.map(&:code)).to eq [:already_verified]
    end
  end
end
