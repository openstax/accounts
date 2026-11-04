require 'rails_helper'

RSpec.describe EmailDelivery, type: :model do
  let(:email_address) { FactoryBot.create(:email_address) }
  let(:delivery) { described_class.track_signup_confirmation!(email_address) }

  describe '.track_signup_confirmation!' do
    it 'records a queued signup confirmation for the address as it is now' do
      expect(delivery).to be_queued
      expect(delivery.kind).to eq(EmailDelivery::SIGNUP_CONFIRMATION)
      expect(delivery.recipient).to eq(email_address.value)
      expect(delivery.status_changed_at).to be_present
    end
  end

  describe '#advance!' do
    it 'moves up the ranking' do
      expect(delivery.advance!(:sent, sent_at: Time.current)).to be_truthy
      expect(delivery.reload).to be_sent
      expect(delivery.sent_at).to be_present
    end

    it 'ignores an event that would move it down, since SES events arrive out of order' do
      delivery.advance!(:delivered, detail: '250 OK')

      expect(delivery.advance!(:sent)).to eq(false)
      expect(delivery.reload).to be_delivered
      expect(delivery.status_detail).to eq('250 OK')
    end

    it 'lets a newer event of the same rank refresh the detail' do
      delivery.advance!(:delayed, detail: 'first', at: 2.minutes.ago)
      delivery.advance!(:delayed, detail: 'second', at: 1.minute.ago)

      expect(delivery.reload.status_detail).to eq('second')
    end

    it 'ignores an older event of the same rank arriving late' do
      newer = 1.minute.ago
      delivery.advance!(:delayed, detail: 'newer', at: newer)

      expect(delivery.advance!(:delayed, detail: 'older', at: 5.minutes.ago)).to eq(false)
      expect(delivery.reload.status_detail).to eq('newer')
      expect(delivery.status_changed_at).to be_within(1.second).of(newer)
    end

    it 'lets repeated calls without a timestamp through, as send retries make' do
      delivery.advance!(:send_error, detail: 'first')
      delivery.advance!(:send_error, detail: 'second')

      expect(delivery.reload.status_detail).to eq('second')
    end

    it 'lets a complaint override a delivery' do
      delivery.advance!(:delivered)
      delivery.advance!(:complained, detail: 'abuse')

      expect(delivery.reload).to be_complained
    end
  end

  describe '.event_tracking_enabled?' do
    def stub_ses(**ses)
      secrets = Rails.application.secrets.deep_dup
      secrets[:aws] = { ses: ses }
      allow(Rails.application).to receive(:secrets).and_return(secrets)
    end

    it 'needs both the configuration set and the events topic' do
      stub_ses(configuration_set: 'set', events_topic_arn: 'arn:topic')
      expect(described_class.event_tracking_enabled?).to eq(true)
    end

    it 'is off without the events topic, since the webhook would reject every notification' do
      stub_ses(configuration_set: 'set')
      expect(described_class.event_tracking_enabled?).to eq(false)
    end

    it 'is off without the configuration set' do
      stub_ses(events_topic_arn: 'arn:topic')
      expect(described_class.event_tracking_enabled?).to eq(false)
    end
  end

  describe '.signup_confirmation_stats' do
    before { Rails.cache.clear }

    it 'summarizes deliverability and delivery time over the window' do
      now = Time.current
      3.times do |i|
        described_class.track_signup_confirmation!(email_address).update!(
          status: :delivered, created_at: now - 1.hour, delivered_at: now - 1.hour + (i + 1) * 10
        )
      end
      described_class.track_signup_confirmation!(email_address).update!(status: :bounced)
      described_class.track_signup_confirmation!(email_address).update!(created_at: 8.days.ago)

      stats = described_class.signup_confirmation_stats

      expect(stats[:total]).to eq(4)
      expect(stats[:delivered_percent]).to eq(75.0)
      expect(stats[:problem_percent]).to eq(25.0)
      expect(stats[:median_seconds_to_deliver]).to eq(20)
      expect(stats[:p90_seconds_to_deliver]).to eq(28)
    end

    it 'handles an empty window' do
      stats = described_class.signup_confirmation_stats

      expect(stats[:total]).to eq(0)
      expect(stats[:delivered_percent]).to be_nil
      expect(stats[:median_seconds_to_deliver]).to be_nil
    end
  end
end
