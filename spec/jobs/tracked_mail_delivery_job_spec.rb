require 'rails_helper'

RSpec.describe TrackedMailDeliveryJob, type: :job do
  let(:email_address) { FactoryBot.create(:email_address) }
  let!(:delivery) { EmailDelivery.track_signup_confirmation!(email_address) }

  def deliver
    NewflowMailer.signup_email_confirmation(
      email_address: email_address, email_delivery_id: delivery.id
    ).deliver_later
    perform_enqueued_jobs
  end

  it 'stores the SES message id once SES accepts the email' do
    allow_any_instance_of(Mail::Message).to receive(:deliver) do |message|
      message.header[:ses_message_id] = '0100018c-abc'
      message
    end

    deliver

    expect(delivery.reload).to be_sent
    expect(delivery.ses_message_id).to eq('0100018c-abc')
  end

  it 'records a send error and re-raises so delayed_job retries' do
    allow_any_instance_of(Mail::Message).to receive(:deliver).and_raise(
      Aws::SES::Errors::Throttling.new(nil, 'Maximum sending rate exceeded.')
    )

    expect { deliver }.to raise_error(Aws::SES::Errors::Throttling)

    expect(delivery.reload).to be_send_error
    expect(delivery.status_detail).to include('Maximum sending rate exceeded.')
    expect(delivery.send_attempts).to eq(1)
  end

  it 'records a malformed-request rejection as not sent, without retrying' do
    allow(Sentry).to receive(:capture_exception)
    allow_any_instance_of(Mail::Message).to receive(:deliver).and_raise(
      Aws::SES::Errors::InvalidParameterValue.new(
        nil, 'Local address contains control or whitespace'
      )
    )

    expect { deliver }.not_to raise_error

    expect(delivery.reload).to be_rejected
    expect(delivery.status_detail).to include('Local address contains control or whitespace')
  end

  it 'delivers mail without a tracked delivery like the stock job' do
    expect {
      NewflowMailer.reset_password_email(
        user: FactoryBot.create(:user, login_token: 'abc', login_token_expires_at: 1.day.from_now),
        email_address: 'someone@example.org'
      ).deliver_later
      perform_enqueued_jobs
    }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
