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

    describe 'when SES rejects the request as malformed' do
      before do
        allow_any_instance_of(Mail::Message).to receive(:deliver).and_raise(
          Aws::SES::Errors::InvalidParameterValue.new(nil, 'Local address contains control or whitespace')
        )
      end

      it 'reports a warning to Sentry instead of raising so the job is not retried' do
        expect(Sentry).to receive(:capture_exception).with(
          instance_of(Aws::SES::Errors::InvalidParameterValue),
          hash_including(level: :warning)
        )

        expect {
          NewflowMailer.signup_email_confirmation(email_address: email, show_pin: true).deliver_now
        }.not_to raise_error
      end
    end

    describe 'sends email confirmation' do
      it 'has basic header and from info and greeting' do
        mail = NewflowMailer.signup_email_confirmation email_address: email

        expect(mail.header['to'].to_s).to eq('to@example.org')
        expect(mail.from).to eq(["noreply@openstax.org"])
        expect(mail.body.encoded).to include("Welcome to OpenStax!")
        expect(mail.attachments['openstax-logo.png']).to be_present
        expect(mail.attachments['rice-logo.png']).to be_present
        expect(mail.body.encoded).to include("src=\"cid:#{mail.attachments['openstax-logo.png'].cid}\"")
        expect(mail.body.encoded).to include("src=\"cid:#{mail.attachments['rice-logo.png'].cid}\"")
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
          expect(mail.text_part.body.decoded).not_to include(pin)
        end
      end

      it 'has a plain-text alternative alongside the HTML, for spam filters and text-only clients' do
        mail = NewflowMailer.signup_email_confirmation(email_address: email)

        expect(mail.html_part.body.decoded).to include('Welcome to OpenStax!')
        expect(mail.text_part.body.decoded).to include("Your PIN is: #{pin}")
        expect(mail.text_part.body.decoded).to include(confirm_url)
        expect(mail.attachments['openstax-logo.png']).to be_inline
      end
    end

    describe 'SES event publishing' do
      let(:delivery) { EmailDelivery.track_signup_confirmation!(email) }

      it 'tags a tracked email with the configuration set and its delivery id' do
        allow(EmailDelivery).to receive(:configuration_set).and_return('accounts-test-transactional')

        mail = NewflowMailer.signup_email_confirmation(email_address: email, email_delivery_id: delivery.id)

        expect(mail['X-SES-CONFIGURATION-SET'].to_s).to eq('accounts-test-transactional')
        expect(mail['X-SES-MESSAGE-TAGS'].to_s).to eq(
          "email_type=signup_confirmation, email_delivery_id=#{delivery.id}, accounts_env=test"
        )
      end

      it 'adds no SES headers when no configuration set is configured' do
        mail = NewflowMailer.signup_email_confirmation(email_address: email, email_delivery_id: delivery.id)

        expect(mail['X-SES-CONFIGURATION-SET']).to be_nil
        expect(mail['X-SES-MESSAGE-TAGS']).to be_nil
      end

      it 'adds no SES headers to an untracked email' do
        allow(EmailDelivery).to receive(:configuration_set).and_return('accounts-test-transactional')

        mail = NewflowMailer.signup_email_confirmation(email_address: email)

        expect(mail['X-SES-CONFIGURATION-SET']).to be_nil
      end
    end
  end
end
