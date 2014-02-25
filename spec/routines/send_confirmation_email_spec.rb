require 'spec_helper'

describe SendConfirmationEmail do
  let(:create_email) { FactoryGirl.create(:email_address) }

  context 'when email address is already verified' do
    it 'does not send confirmation email' do
      email = create_email
      email.verified = true
      email.save
      expect_any_instance_of(ConfirmationMailer).not_to receive(:instructions)

      result = SendConfirmationEmail.call(email)
      expect(result.errors).not_to be_present
      refetched_email = EmailAddress.find(email.id)
      expect(refetched_email.confirmation_sent_at).to be_nil
    end
  end

  context 'when email address is not verified' do
    it 'sends a confirmation email' do
      email = create_email
      email.confirmation_code = '1111'
      email.save
      expect_any_instance_of(ConfirmationMailer).to receive(:instructions)
      now = Time.parse('2014-02-24 10:00')
      Time.stub(:now).and_return(now)

      result = SendConfirmationEmail.call(email)
      expect(result.errors).not_to be_present
      refetched_email = EmailAddress.find(email.id)
      expect(refetched_email.confirmation_sent_at.utc).to eq(now.utc)
    end

    it 'errors with no confirmation code' do
      email = create_email
      email.save
      expect_any_instance_of(ConfirmationMailer).not_to receive(:instructions)

      result = SendConfirmationEmail.call(email)
      expect(result.errors).to be_present
    end
  end

end
