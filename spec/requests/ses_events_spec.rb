require 'rails_helper'

RSpec.describe 'SES event notifications', type: :request do
  let(:topic_arn) { 'arn:aws:sns:us-east-1:123456789012:accounts-test-ses-events' }
  let(:verifier) { instance_double(Aws::SNS::MessageVerifier, authentic?: true) }
  let(:email_address) { FactoryBot.create(:email_address) }
  let(:delivery) { EmailDelivery.track_signup_confirmation!(email_address) }

  let(:ses_event) do
    {
      'eventType' => 'Delivery',
      'mail' => {
        'messageId' => 'abc',
        'tags' => { 'email_delivery_id' => [delivery.id.to_s], 'accounts_env' => ['test'] }
      },
      'delivery' => { 'timestamp' => Time.current.iso8601, 'smtpResponse' => '250 OK' }
    }
  end

  def sns_message(type, extra = {})
    { 'Type' => type, 'TopicArn' => topic_arn, 'MessageId' => 'm-1' }.merge(extra)
  end

  def post_sns(message)
    post '/i/ses/events',
         params: message.to_json,
         headers: { 'CONTENT_TYPE' => 'text/plain; charset=UTF-8' }
  end

  before do
    require 'aws-sdk-sns'
    allow(SesEventsController).to receive(:verifier).and_return(verifier)
    secrets = Rails.application.secrets.deep_dup
    secrets[:aws] = { ses: { events_topic_arn: topic_arn } }
    allow(Rails.application).to receive(:secrets).and_return(secrets)
  end

  it 'applies a notification to its delivery' do
    post_sns(sns_message('Notification', 'Message' => ses_event.to_json))

    expect(response).to have_http_status(:ok)
    expect(delivery.reload).to be_delivered
  end

  it 'refuses a message with a bad signature' do
    allow(verifier).to receive(:authentic?).and_return(false)

    post_sns(sns_message('Notification', 'Message' => ses_event.to_json))

    expect(response).to have_http_status(:forbidden)
    expect(delivery.reload).to be_queued
  end

  it 'refuses a validly signed message from some other topic' do
    post_sns(
      sns_message('Notification', 'TopicArn' => "#{topic_arn}-other", 'Message' => ses_event.to_json)
    )

    expect(response).to have_http_status(:forbidden)
    expect(delivery.reload).to be_queued
  end

  it 'refuses everything when no topic is configured' do
    allow(Rails.application).to receive(:secrets).and_call_original

    post_sns(sns_message('Notification', 'Message' => ses_event.to_json))

    expect(response).to have_http_status(:forbidden)
  end

  it 'rejects a body that is not JSON' do
    post '/i/ses/events', params: 'nope', headers: { 'CONTENT_TYPE' => 'text/plain' }

    expect(response).to have_http_status(:bad_request)
  end

  it 'confirms the subscription with SNS' do
    url = 'https://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&Token=t'
    expect(Net::HTTP).to receive(:get_response)
      .with(URI.parse(url))
      .and_return(Net::HTTPOK.new('1.1', '200', 'OK'))

    post_sns(sns_message('SubscriptionConfirmation', 'SubscribeURL' => url))

    expect(response).to have_http_status(:ok)
  end

  it 'fails the request when SNS does not accept the confirmation, so SNS retries' do
    url = 'https://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&Token=t'
    allow(Net::HTTP).to receive(:get_response)
      .and_return(Net::HTTPForbidden.new('1.1', '403', 'Forbidden'))

    expect { post_sns(sns_message('SubscriptionConfirmation', 'SubscribeURL' => url)) }
      .to raise_error(/HTTP 403/)
  end

  it 'lets a network error on confirmation propagate' do
    url = 'https://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&Token=t'
    allow(Net::HTTP).to receive(:get_response).and_raise(Errno::ECONNREFUSED)

    expect { post_sns(sns_message('SubscriptionConfirmation', 'SubscribeURL' => url)) }
      .to raise_error(Errno::ECONNREFUSED)
  end

  it 'will not fetch a SubscribeURL outside SNS' do
    allow(Sentry).to receive(:capture_message)
    expect(Net::HTTP).not_to receive(:get_response)

    post_sns(sns_message('SubscriptionConfirmation', 'SubscribeURL' => 'https://evil.example.com/x'))

    expect(response).to have_http_status(:ok)
  end
end
