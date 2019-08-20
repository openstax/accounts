require 'rails_helper'

RSpec.describe Api::V1::ContactInfosController, type: :controller, api: true, version: :v1 do

  let!(:untrusted_application)     { FactoryBot.create :doorkeeper_application }

  let!(:right_user) { FactoryBot.create :user }
  let!(:wrong_user) { FactoryBot.create :user }

  let!(:right_user_token)    { FactoryBot.create :doorkeeper_access_token,
                                                  application: untrusted_application,
                                                  resource_owner_id: right_user.id }
  let!(:wrong_user_token)    { FactoryBot.create :doorkeeper_access_token,
                                                  application: untrusted_application,
                                                  resource_owner_id: wrong_user.id }

  let!(:contact_info) {
    AddEmailToUser.call("bob@example.com", right_user)
    right_user.contact_infos.first
  }

  describe "#resend_confirmation" do
    it "403s if the wrong user makes the request" do
      api_put :resend_confirmation, wrong_user_token, params: {id: contact_info.id}
      expect(response).to have_http_status :forbidden
    end

    it "returns an `already_confirmed` error when confirmed" do
      ConfirmContactInfo.call(contact_info)
      api_put :resend_confirmation, right_user_token, params: {id: contact_info.id}
      expect(response).to have_api_error_status(422)
      expect(response).to have_api_error_code('already_confirmed')
    end

    it "sends the confirmation if all good and `send_pin` not specified" do
      expect(SendContactInfoConfirmation).to receive(:call).with(contact_info: contact_info, send_pin: nil)
      api_put :resend_confirmation, right_user_token, params: {id: contact_info.id}
      expect(response).to have_http_status(:no_content)
    end

    it "sends the confirmation if all good and `send_pin` false" do
      expect(SendContactInfoConfirmation).to receive(:call).with(contact_info: contact_info, send_pin: false)
      api_put :resend_confirmation, right_user_token, params: {id: contact_info.id},
                                                      body: {send_pin: false}.to_json
      expect(response).to have_http_status(:no_content)
    end

    it "sends the confirmation if all good and `send_pin` true" do
      expect(SendContactInfoConfirmation).to receive(:call).with(contact_info: contact_info, send_pin: true)
      api_put :resend_confirmation, right_user_token, params: {id: contact_info.id},
                                                      body: {send_pin: true}.to_json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "#confirm_by_pin" do
    it "204s if the pin matches and all stars align" do
      api_put :confirm_by_pin, right_user_token, params: {id: contact_info.id},
                                                 body: {pin: contact_info.confirmation_pin}.to_json
      expect(contact_info.reload).to be_confirmed
      expect(response).to have_http_status(:no_content)
    end

    it "403s if the wrong user makes the request" do
      api_put :confirm_by_pin, wrong_user_token, params: {id: contact_info.id}
      expect(response).to have_http_status :forbidden
    end

    it "204s if already confirmed" do
      ConfirmContactInfo.call(contact_info)
      api_put :confirm_by_pin, right_user_token, params: {id: contact_info.id}
      expect(response).to have_http_status(:no_content)
    end

    it "422s if incorrect pin" do
      api_put :confirm_by_pin, right_user_token, params: {id: contact_info.id},
                                                 body: {pin: 'blah'}.to_json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to have_api_error_status(422)
      expect(response).to have_api_error_code('pin_not_correct')
    end

    it "422s if no more pin attempts" do
      ConfirmByPin.max_pin_failures.times { ConfirmByPin.call(contact_info: contact_info, pin: "whatever") }

      api_put :confirm_by_pin, right_user_token, params: {id: contact_info.id},
                                                 body: {pin: 'blah'}.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to have_api_error_status(422)
      expect(response).to have_api_error_code('no_pin_confirmation_attempts_remaining')
    end
  end

end
