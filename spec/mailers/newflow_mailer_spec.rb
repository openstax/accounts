require 'rails_helper'

module Newflow
  describe NewflowMailer, type: :mailer do
    let(:pin) { '123456' }
    let(:code) { '1234' }
    let(:confirm_url) { "http://localhost:2999/i/verify_email_by_code/#{code}" }
    let(:user) { FactoryBot.create :user, first_name: 'John', last_name: 'Doe', suffix: 'Jr.' }
    let(:email) {
      FactoryBot.create :email_address,
                        value: 'to@example.org',
                        user_id: user.id,
                        confirmation_code: code,
                        confirmation_pin: pin
    }

    describe 'sends email confirmation' do
      it 'has basic header and from info and greeting' do
        mail = NewflowMailer.signup_email_confirmation email_address: email

        expect(mail.header['to'].to_s).to eq('to@example.org')
        expect(mail.from).to eq(["noreply@openstax.org"])
        expect(mail.body.encoded).to include("Welcome to OpenStax!")
      end

      context 'when show_pin is not sent' do
        it 'includes PIN info in the email' do
          mail = NewflowMailer.signup_email_confirmation(email_address: email)

          expect(mail.subject).to eq("[OpenStax] Your OpenStax account PIN has arrived: #{pin}")
          expect(mail.body.encoded).to include("<a href=\"#{confirm_url}\"")
          expect(mail.body.encoded).to include("use your pin: <b id='pin'>#{pin}</b>")
        end
      end

      context 'when show_pin is nil' do
        it 'includes PIN info in the email' do
          mail = NewflowMailer.signup_email_confirmation(email_address: email, show_pin: nil)

          expect(mail.subject).to eq("[OpenStax] Your OpenStax account PIN has arrived: #{pin}")
          expect(mail.body.encoded).to include("<a href=\"#{confirm_url}\"")
          expect(mail.body.encoded).to include("use your pin: <b id='pin'>#{pin}</b>")
        end
      end

      context 'when show_pin is false' do
        it 'excludes the pin code from the email' do
          mail = NewflowMailer.signup_email_confirmation(email_address: email, show_pin: false)

          expect(mail.subject).to eq("[OpenStax] Confirm your email address")
          expect(mail.body.encoded).to include("<a href=\"#{confirm_url}\"")
          expect(mail.body.encoded).not_to include("use your pin: <b id='pin'>#{pin}</b>")
        end
      end
    end
  end
end
