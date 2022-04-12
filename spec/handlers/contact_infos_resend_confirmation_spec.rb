require 'rails_helper'

describe ContactInfosResendConfirmation, type: :handler do

  let!(:contact_info) { FactoryBot.create :email_address }
  let!(:user)         { contact_info.user }

  context 'success' do
    it 'resends the confirmation message' do
      cc = contact_info.confirmation_code

      expect(contact_info.confirmation_code).not_to be_blank
      expect_any_instance_of(NewflowMailer).to(
        receive(:instructions).with(email_address: contact_info, send_pin: false)
      )

        ContactInfosResendConfirmation.call(caller: user,
                                          params: { id: contact_info.id })
    end
  end

end
