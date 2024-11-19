require 'rails_helper'

module Newflow
  describe NewflowMailer, type: :mailer do
    let(:user) { FactoryBot.create :user, first_name: 'John', last_name: 'Doe', suffix: 'Jr.' }
    let(:email) { FactoryBot.create :email_address, value: 'to@example.org',
                                    user_id: user.id, confirmation_code: '1234', confirmation_pin: '123456' }

    describe 'sends email confirmation' do
      it 'has basic header and from info and greeting' do
        mail = NewflowMailer.signup_email_confirmation email_address: email

        expect(mail.header['to'].to_s).to eq('to@example.org')
        expect(mail.from).to eq(["noreply@openstax.org"])
        expect(mail.body.encoded).to include("Welcome to OpenStax!")
      end

      it "has PIN info" do
        allow(ConfirmByPin).to receive(:sequential_failure_for) { Hashie::Mash.new('attempts_remaining?' => true)}

        mail = NewflowMailer.signup_email_confirmation email_address: email

        expect(mail.subject).to eq("[OpenStax] Your OpenStax account PIN has arrived: 123456")
        expect(mail.body.encoded).to include('<a href="http://localhost:2999/i/verify_email_by_code/1234"')
        expect(mail.body.encoded).to include('use your pin: <b id=\'pin\'>123456</b>')
      end
    end
  end
end
