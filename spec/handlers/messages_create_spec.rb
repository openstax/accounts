require 'spec_helper'

describe MessagesCreate do

  let!(:trusted_application)   {
    FactoryGirl.create :doorkeeper_application, :trusted,
                       email_from_address: 'app@example.com'
  }
  let!(:trusted_application_token) { FactoryGirl.create :doorkeeper_access_token,
                                                application: trusted_application,
                                                resource_owner_id: nil }
  let!(:api_user)              { OpenStax::Api::ApiUser.new(
                                   trusted_application_token, nil) }

  let!(:user_1)                { FactoryGirl.create :user }

  (2..13).each do |n|
    let!("user_#{n}".to_sym)   { FactoryGirl.create :user_with_emails }
  end

  let!(:message_params)        {
    { user_id: user_1.id,
      send_externally_now: true,
      to: {literals: [user_2.contact_infos.first.value,
                      user_3.contact_infos.first.value],
           user_ids: [user_4.id,
                      user_5.id]},
      cc: {literals: [user_6.contact_infos.first.value,
                      user_7.contact_infos.first.value],
           user_ids: [user_8.id,
                      user_9.id]},
      bcc: {literals: [user_10.contact_infos.first.value,
                       user_11.contact_infos.first.value],
            user_ids: [user_12.id,
                       user_13.id]},
      subject: 'Hello World',
      subject_prefix: '[Testing]',
      body: { html: '<p>Hello there!</p>',
              text: 'Hello there!',
              short_text: 'Hello!' }}
  }

  context 'invalid params' do

    let!(:invalid_params_1) { message_params.except(:to) }
    let!(:invalid_params_2) { message_params.except(:subject) }
    let!(:invalid_params_3) { message_params.except(:body) }
    let!(:invalid_params_4) { msg = message_params.dup
                              msg[:to] = {}
                              msg }
    let!(:invalid_params_5) { msg = message_params.dup
                              msg[:body] = {}
                              msg }

    it 'does not create or send messages with invalid params' do
      Mail::TestMailer.deliveries.clear

      c = Message.count

      expect(MessagesCreate.handle(params: invalid_params_1,
                     caller: api_user).errors).not_to be_empty

      expect(Message.count).to eq(c)

      expect(MessagesCreate.handle(params: invalid_params_2,
                     caller: api_user).errors).not_to be_empty

      expect(Message.count).to eq(c)

      expect(MessagesCreate.handle(params: invalid_params_3,
                     caller: api_user).errors).not_to be_empty

      expect(Message.count).to eq(c)

      expect(MessagesCreate.handle(params: invalid_params_4,
                     caller: api_user).errors).not_to be_empty

      expect(Message.count).to eq(c)

      expect(MessagesCreate.handle(params: invalid_params_5,
                     caller: api_user).errors).not_to be_empty

      expect(Message.count).to eq(c)

      expect(Mail::TestMailer.deliveries).to be_empty
    end
  end

  context 'valid params' do
    let!(:expected_response) {
      { 'application_id' => trusted_application.id,
        'user_id' => user_1.id,
        'send_externally_now' => true,
        'to' => {'user_ids' => Set.new([user_2.id, user_3.id, user_4.id, user_5.id])},
        'cc' => {'user_ids' => Set.new([user_6.id, user_7.id, user_8.id, user_9.id])},
        'bcc' => {'user_ids' => Set.new([user_10.id, user_11.id, user_12.id, user_13.id])},
        'subject' => 'Hello World',
        'subject_prefix' => '[Testing]',
        'body' => {'html' => '<p>Hello there!</p>',
                 'text' => 'Hello there!',
                 'short_text' => 'Hello!'} }
    }

    it 'creates and sends message with valid params' do
      Mail::TestMailer.deliveries.clear

      c = Message.count

      msg = MessagesCreate.handle(params: message_params,
              caller: api_user).outputs[:message]

      response = Api::V1::MessageRepresenter.new(msg).to_hash.except('id')
      response['to']['user_ids'] = Set.new response['to']['user_ids']
      response['cc']['user_ids'] = Set.new response['cc']['user_ids']
      response['bcc']['user_ids'] = Set.new response['bcc']['user_ids']
      expect(response).to eq(expected_response)

      expect(Message.count).to eq(c + 1)

      expect(Mail::TestMailer.deliveries.length).to eq(1)
    end
  end

end
