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
    CreateEmailForUser.call("bob@example.com", right_user)
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
      expect(SendContactInfoConfirmation).to receive(:call).with(contact_info: contact_info)
      api_put :resend_confirmation, right_user_token, params: {id: contact_info.id}
      expect(response).to have_http_status(:no_content)
    end

    it "sends the confirmation if all good and `send_pin` false" do
      expect(SendContactInfoConfirmation).to receive(:call).with(contact_info: contact_info)
      api_put :resend_confirmation, right_user_token, params: {id: contact_info.id},
                                                      body: {send_pin: false}.to_json
      expect(response).to have_http_status(:no_content)
    end

    it "sends the confirmation if all good and `send_pin` true" do
      expect(SendContactInfoConfirmation).to receive(:call).with(contact_info: contact_info)
      api_put :resend_confirmation, right_user_token, params: {id: contact_info.id},
                                                      body: {send_pin: true}.to_json
      expect(response).to have_http_status(:no_content)
    end
  end

end
