require 'rails_helper'

RSpec.describe Newflow::SendSignupConfirmationEmail, type: :routine do
  include ActiveJob::TestHelper

  let(:email_address) { FactoryBot.create(:email_address) }

  it 'records a queued delivery' do
    expect { described_class.call(email_address: email_address) }.to(
      change { email_address.email_deliveries.signup_confirmations.queued.count }.by(1)
    )
  end

  it 'enqueues the email ahead of every other job, on the queue mail already uses' do
    described_class.call(email_address: email_address)

    job = enqueued_jobs.last
    expect(job[:job]).to eq(TrackedMailDeliveryJob)
    expect(job[:queue]).to eq(ActionMailer::MailDeliveryJob.new.queue_name)
    expect(job['priority']).to eq(-20)

    lowest_other_priority = Delayed::Worker.queue_attributes.values.map { |attrs|
 attrs[:priority] }.min
    expect(job['priority']).to be < lowest_other_priority
  end

  it "keeps that priority on the delayed_job row despite the queue's own priority" do
    described_class.call(email_address: email_address)
    job = ActiveJob::Base.deserialize(enqueued_jobs.last)

    original = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = true
    begin
      ActiveJob::QueueAdapters::DelayedJobAdapter.new.enqueue(job)
    ensure
      Delayed::Worker.delay_jobs = original
    end

    expect(Delayed::Job.last.priority).to eq(-20)
  end

  it 'marks the delivery sent once the job runs' do
    result = described_class.call(email_address: email_address)

    perform_enqueued_jobs

    delivery = result.outputs.email_delivery.reload
    expect(delivery).to be_sent
    expect(delivery.sent_at).to be_present
    expect(delivery.send_attempts).to eq(1)
  end
end
