require 'rails_helper'

describe Api::V1::MessagesController, type: :controller, api: true, version: :v1 do

  let!(:untrusted_application) {
    FactoryBot.create :doorkeeper_application,
                       email_from_address: 'app@example.com'
  }
  let!(:trusted_application)   {
    FactoryBot.create :doorkeeper_application, :trusted,
                       email_from_address: 'app@example.com'
  }
  let!(:user_1)                { FactoryBot.create :user }

  (2..13).each do |n|
    let!("user_#{n}".to_sym)   { FactoryBot.create :user_with_emails }
  end

  let!(:user_1_trusted_token)   { FactoryBot.create :doorkeeper_access_token,
                                    application: trusted_application,
                                    resource_owner_id: user_1.id }
  let!(:user_1_untrusted_token) { FactoryBot.create :doorkeeper_access_token,
                                    application: untrusted_application,
                                    resource_owner_id: user_1.id }
  let!(:untrusted_application_token) {
    FactoryBot.create :doorkeeper_access_token,
                       application: untrusted_application,
                       resource_owner_id: nil
  }
  let!(:trusted_application_token) {
    FactoryBot.create :doorkeeper_access_token,
                       application: trusted_application,
                       resource_owner_id: nil
  }

  context "create" do

    let!(:message_params) {
      { user_id: user_1.id,
        send_externally_now: true,
        to: {literals: [user_2.contact_infos.first.value,
                        user_3.contact_infos.first.value],
             user_ids: [user_4.id, user_5.id]},
        cc: {literals: [user_6.contact_infos.first.value,
                        user_7.contact_infos.first.value],
             user_ids: [user_8.id, user_9.id]},
        bcc: {literals: [user_10.contact_infos.first.value,
                         user_11.contact_infos.first.value],
              user_ids: [user_12.id, user_13.id]},
        subject: 'Hello World',
        subject_prefix: '[Testing]',
        body: { html: '<p>Hello there!</p>',
                text: 'Hello there!',
                short_text: 'Hello!' }}
    }

    let!(:expected_response) {
      { 'application_id' => trusted_application.id,
        'user_id' => user_1.id,
        'send_externally_now' => true,
        'to' => {'user_ids' => [user_2.id, user_3.id, user_4.id, user_5.id]},
        'cc' => {'user_ids' => [user_6.id, user_7.id, user_8.id, user_9.id]},
        'bcc' => {'user_ids' => [user_10.id, user_11.id, user_12.id, user_13.id]},
        'subject' => 'Hello World',
        'subject_prefix' => '[Testing]',
        'body' => {'html' => '<p>Hello there!</p>',
                 'text' => 'Hello there!',
                 'short_text' => 'Hello!'}}
    }

    it "does not allow users or untrusted applications to send messages" do
      Mail::TestMailer.deliveries.clear

      api_post :create, user_1_untrusted_token, params: message_params
      expect(response).to have_http_status :forbidden

      api_post :create, user_1_trusted_token, params: message_params
      expect(response).to have_http_status :forbidden

      api_post :create, untrusted_application_token, params: message_params
      expect(response).to have_http_status :forbidden

      # These exceptions are no longer "notified" out
      expect(Mail::TestMailer.deliveries.size).to eq(0)
    end

    it "creates and sends messages for trusted applications" do
      Mail::TestMailer.deliveries.clear

      expect{api_post :create, trusted_application_token,
                      params: message_params}.not_to raise_error
      expect(response.code).to eq('201')

      outcome = JSON.parse(response.body)
      expect(outcome.except('id')).to eq(expected_response)

      expect(Mail::TestMailer.deliveries.length).to eq(1)
    end

  end

end
