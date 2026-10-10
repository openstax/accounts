require 'rails_helper'

RSpec.describe ProcessSesEvent, type: :routine do
  let(:email_address) { FactoryBot.create(:email_address) }
  let!(:delivery) do
    EmailDelivery.track_signup_confirmation!(email_address).tap do |d|
      d.advance!(:sent, sent_at: 1.minute.ago)
    end
  end

  # Shapes follow https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-examples.html
  def event(type, body = {}, tags = {})
    {
      'eventType' => type,
      'mail' => {
        'timestamp' => '2026-10-08T15:00:00.000Z',
        'messageId' => '0100018c-message',
        'headers' => [{ 'name' => 'To', 'value' => email_address.value }],
        'tags' => {
          'email_type' => ['signup_confirmation'],
          'email_delivery_id' => [delivery.id.to_s],
          'accounts_env' => ['test']
        }.merge(tags)
      }
    }.merge(body)
  end

  it 'records a delivery with the time it took' do
    delivered = {
      'timestamp' => '2026-10-08T15:00:04.000Z',
      'smtpResponse' => '250 2.0.0 OK',
      'reportingMTA' => 'a8-60.smtp-out.amazonses.com'
    }

    described_class.call(event: event('Delivery', 'delivery' => delivered))

    delivery.reload
    expect(delivery).to be_delivered
    expect(delivery.delivered_at).to eq(Time.zone.parse('2026-10-08T15:00:04Z'))
    expect(delivery.status_detail).to eq('250 2.0.0 OK')
    expect(delivery.ses_message_id).to eq('0100018c-message')
    expect(delivery.last_event['mail']).not_to have_key('headers')
  end

  it 'records a delay with why and how long SES keeps trying' do
    delay = {
      'timestamp' => '2026-10-08T15:01:00.000Z',
      'delayType' => 'TransientCommunicationFailure',
      'expirationTime' => '2026-10-08T21:00:00.000Z',
      'delayedRecipients' => [{ 'diagnosticCode' => '421 4.7.0 Try again later, greylisted' }]
    }

    described_class.call(event: event('DeliveryDelay', 'deliveryDelay' => delay))

    expect(delivery.reload).to be_delayed
    expect(delivery.status_detail).to eq(
      'TransientCommunicationFailure: 421 4.7.0 Try again later, greylisted ' \
      '(SES keeps retrying until 2026-10-08T21:00:00.000Z)'
    )
  end

  it 'records a bounce with the type and the server diagnostic' do
    bounce = {
      'bounceType' => 'Permanent',
      'bounceSubType' => 'General',
      'timestamp' => '2026-10-08T15:00:05.000Z',
      'bouncedRecipients' => [{ 'diagnosticCode' => 'smtp; 550 5.1.1 user unknown' }]
    }

    described_class.call(event: event('Bounce', 'bounce' => bounce))

    expect(delivery.reload).to be_bounced
    expect(delivery.status_detail).to eq('Permanent/General: smtp; 550 5.1.1 user unknown')
  end

  it 'records a complaint' do
    complaint = { 'complaintFeedbackType' => 'abuse' }

    described_class.call(event: event('Complaint', 'complaint' => complaint))

    expect(delivery.reload).to be_complained
  end

  it 'records a reject' do
    described_class.call(event: event('Reject', 'reject' => { 'reason' => 'Bad content' }))

    expect(delivery.reload).to be_rejected
    expect(delivery.status_detail).to eq('Bad content')
  end

  it 'ignores a Send that arrives after the Delivery' do
    delivery.advance!(:delivered)

    described_class.call(event: event('Send', 'send' => {}))

    expect(delivery.reload).to be_delivered
  end

  it "ignores another environment's event, since delivery ids collide across environments" do
    result = described_class.call(
      event: event('Bounce', { 'bounce' => {} }, { 'accounts_env' => ['staging'] })
    )

    expect(result.outputs.email_delivery).to be_nil
    expect(delivery.reload).to be_sent
  end

  it 'ignores mail it did not tag' do
    untagged = event('Delivery', 'delivery' => {})
    untagged['mail']['tags'] = { 'accounts_env' => ['test'] }

    expect(described_class.call(event: untagged).outputs.email_delivery).to be_nil
  end

  it 'ignores event types it does not track' do
    described_class.call(event: event('Open', 'open' => {}))

    expect(delivery.reload).to be_sent
  end
end
