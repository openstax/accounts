require 'rails_helper'

module Newflow
  describe ResendSignupEmail, type: :routine do
    let(:user) { FactoryBot.create(:user, state: 'unverified') }
    let(:email) { FactoryBot.create(:email_address, user: user, verified: false) }

    def codes(result)
      result.errors.map(&:code)
    end

    it 'sends the confirmation email again with the same PIN' do
      pin = email.confirmation_pin

      expect {
        described_class.call(email_address: email)
      }.to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)

      expect(email.reload.confirmation_pin).to eq pin
      expect(email.confirmation_sent_at).to be_within(5.seconds).of(Time.current)
    end

    it 'enqueues at the signup-confirmation priority' do
      described_class.call(email_address: email)

      expect(enqueued_jobs.last['priority']).to eq SendSignupConfirmationEmail::PRIORITY
    end

    it 'refuses a second send within a minute' do
      email.update_column(:confirmation_sent_at, 30.seconds.ago)

      result = nil
      expect {
        result = described_class.call(email_address: email)
      }.not_to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)

      expect(codes(result)).to eq [:resent_too_soon]
    end

    it 'sends again once the minute has passed' do
      email.update_column(:confirmation_sent_at, 2.minutes.ago)

      expect {
        described_class.call(email_address: email)
      }.to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)
    end

    it 'refuses the second of two overlapping resends that both read the old timestamp' do
      first = EmailAddress.find(email.id)
      second = EmailAddress.find(email.id)
      expect(second.confirmation_sent_at).to be_nil

      expect {
        expect(described_class.call(email_address: first).errors).to be_empty
      }.to have_enqueued_mail(NewflowMailer, :signup_email_confirmation).once

      expect(second.confirmation_sent_at).to be_nil
      result = nil
      expect {
        result = described_class.call(email_address: second)
      }.not_to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)
      expect(codes(result)).to eq [:resent_too_soon]
    end

    it 'does nothing for a verified address' do
      email.update_column(:verified, true)

      result = nil
      expect {
        result = described_class.call(email_address: email)
      }.not_to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)

      expect(codes(result)).to eq [:already_verified]
    end

    it 'does not claim an address that was verified after it was loaded' do
      stale = EmailAddress.find(email.id)
      email.update_column(:verified, true)

      result = described_class.call(email_address: stale)

      expect(codes(result)).to eq [:resent_too_soon]
      expect(email.reload.confirmation_sent_at).to be_nil
    end

    describe 'hourly cap' do
      def log_resends(count, at:)
        count.times do
          SecurityLog.create!(user: user, event_type: :signup_email_resent, created_at: at)
        end
      end

      it 'refuses the sixth resend within an hour' do
        log_resends(5, at: 10.minutes.ago)
        email.update_column(:confirmation_sent_at, 5.minutes.ago)

        result = nil
        expect {
          result = described_class.call(email_address: email)
        }.not_to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)

        expect(codes(result)).to eq [:resend_limit_reached]
      end

      it 'allows a fifth resend' do
        log_resends(4, at: 10.minutes.ago)

        expect {
          described_class.call(email_address: email)
        }.to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)
      end

      it 'ignores resends older than an hour and other users' do
        log_resends(5, at: 61.minutes.ago)
        SecurityLog.create!(user: FactoryBot.create(:user), event_type: :signup_email_resent)

        expect {
          described_class.call(email_address: email)
        }.to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)
      end
    end
  end
end
