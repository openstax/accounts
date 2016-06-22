require 'rails_helper'

describe ContactInfosResendConfirmation do

  let!(:contact_info) { FactoryGirl.create :email_address }
  let!(:user)         { contact_info.user }

  context 'success' do
    it 'resends the confirmation message' do
      cc = contact_info.confirmation_code
      expect_any_instance_of(ConfirmationMailer).to(
        receive(:instructions).with(contact_info))
      ContactInfosResendConfirmation.call(caller: user,
                                          params: { id: contact_info.id })

      expect(contact_info.reload.confirmation_code).not_to be_blank
      expect(contact_info.confirmation_code).not_to eq cc
    end
  end

end
