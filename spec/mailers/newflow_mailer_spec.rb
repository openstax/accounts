require 'rails_helper'

describe NewflowMailer, type: :mailer do
  let(:user) { FactoryBot.create :user, first_name: 'John', last_name: 'Doe', suffix: 'Jr.' }
  let(:email) { FactoryBot.create :email_address, value: 'to@example.org',
                                  user_id: user.id, confirmation_code: '1234', confirmation_pin: '123456' }

  describe '' do
    it 'has basic header and from info and greeting' do
      mail = NewflowMailer.signup_email_confirmation email_address: email

      expect(mail.header['to'].to_s).to eq('to@example.org')
      expect(mail.from).to eq(["noreply@openstax.org"])
      expect(mail.body.encoded).to include("Welcome!")
    end

    it "has PIN info when PIN attempts remain" do
      allow(ConfirmByPin).to receive(:sequential_failure_for) { Hashie::Mash.new('attempts_remaining?' => true)}

      mail = NewflowMailer.signup_email_confirmation email_address: email

      expect(mail.subject).to eq("[OpenStax] Use PIN 123456 to confirm your email address")
      expect(mail.body.encoded).to include('Enter your 6-digit')
      expect(mail.body.encoded).to include('Your PIN: <b>123456</b>')
    end

    it "has just link when no PIN attempts remain" do
      allow(ConfirmByPin).to receive(:sequential_failure_for) { Hashie::Mash.new('attempts_remaining?' => false)}

      mail = NewflowMailer.signup_email_confirmation email_address: email

      expect(mail.subject).to eq("[OpenStax] Confirm your email address")
      expect(mail.body.encoded).to include('Click on the link below')
      expect(mail.body.encoded).not_to include('Your PIN')
    end
  end
end
