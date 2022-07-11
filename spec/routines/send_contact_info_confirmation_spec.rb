require 'rails_helper'

describe SendContactInfoConfirmation do
  let(:email) { FactoryBot.create(:email_address) }

  context 'when email address is already verified' do
    it 'does not send confirmation email' do
      email.verified = true
      email.save!

      result = SendContactInfoConfirmation.call(contact_info: email)
      expect(result.errors).not_to be_present
      refetched_email = EmailAddress.find(email.id)
      expect(refetched_email.confirmation_sent_at).to be_nil
    end
  end

  context 'when email address is not verified' do
    it 'sends a confirmation email' do
      now = Time.parse('2014-02-24 10:00')
      allow(Time).to receive(:now).and_return(now)

      result = SendContactInfoConfirmation.call(contact_info: email)
      expect(result.errors).not_to be_present
      refetched_email = EmailAddress.find(email.id)

      expect(refetched_email.confirmation_sent_at.utc).to eq(now.utc)
      expect(refetched_email.confirmation_code).not_to be_blank
    end

    it 'has a confirmation email with url that matches record' do
       expect do
         SendContactInfoConfirmation.call(contact_info: email)
       end.to change { ActionMailer::Base.deliveries.count }.by(1)
       delivery = ActionMailer::Base.deliveries.last
       expect(delivery.body.encoded).to include("verify_email_by_code/#{email.confirmation_code}")
    end

    context 'something goes wrong' do
      it 'does not send an email and sets errors' do
        email.value = '' # cause a failure during save
        result = SendContactInfoConfirmation.call(contact_info: email)
        expect(result.errors).to be_present
      end
    end

    context 'confirmation_pin' do
      it 'is populated with send_pin true' do
        SendContactInfoConfirmation.call(contact_info: email)
        refetched_email = EmailAddress.find(email.id)
        expect(refetched_email.confirmation_pin).not_to be_blank
      end
    end
  end
end
