require 'rails_helper'

describe ConfirmationMailer, type: :mailer do
  let(:user) { FactoryGirl.create :user, first_name: 'John', last_name: 'Doe', suffix: 'Jr.' }
  let(:email) { FactoryGirl.create :email_address, value: 'to@example.org',
                                   user_id: user.id, confirmation_code: '1234', confirmation_pin: '123456' }

  describe "instructions" do

    it 'has basic header and from info and greeting' do
      mail = ConfirmationMailer.instructions email_address: email

      expect(mail.header['to'].to_s).to eq('"John Doe Jr." <to@example.org>')
      expect(mail.from).to eq(["noreply@openstax.org"])
      expect(mail.body.encoded).to include("Hi #{user.casual_name}")
    end

    it 'does not include PIN when directed not to' do
      mail = ConfirmationMailer.instructions email_address: email, send_pin: false

      expect(mail.subject).to eq("Please confirm you OpenStax account")
      expect(mail.body.encoded).not_to include('six-digit PIN')
    end

    it "has PIN info when PIN attempts remain" do
      allow(ConfirmByPin).to receive(:sequential_failure_for) { Hashie::Mash.new('attempts_remaining?' => true)}

      mail = ConfirmationMailer.instructions email_address: email, send_pin: true

      expect(mail.subject).to eq("Please confirm you OpenStax account")
      expect(mail.body.encoded).to include('Enter your unique six-digit PIN in your browser to confirm: 123456')
    end

    it "has just link when no PIN attempts remain" do
      allow(ConfirmByPin).to receive(:sequential_failure_for) { Hashie::Mash.new('attempts_remaining?' => false)}

      mail = ConfirmationMailer.instructions email_address: email, send_pin: true

      expect(mail.subject).to eq("Please confirm you OpenStax account")
      expect(mail.body.encoded).to include('Or, click the link below.')
      expect(mail.body.encoded).not_to include('six-digit PIN')
    end

  end

end
