require 'rails_helper'

RSpec.describe Newflow::SendSignupConfirmationEmail, type: :routine do
  include ActiveJob::TestHelper

  let(:email_address) { FactoryBot.create(:email_address) }

  it 'enqueues the email ahead of every other job, on the queue mail already uses' do
    described_class.call(email_address: email_address)

    job = enqueued_jobs.last
    expect(job[:job]).to eq(ActionMailer::MailDeliveryJob)
    expect(job[:queue]).to eq(ActionMailer::MailDeliveryJob.new.queue_name)
    expect(job['priority']).to eq(-20)

    lowest_other_priority = Delayed::Worker.queue_attributes.values.map { |attrs| attrs[:priority] }.min
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

  it 'passes show_pin through to the mailer' do
    described_class.call(email_address: email_address, show_pin: false)

    args = enqueued_jobs.last['arguments']
    expect(args.last['args'].last['show_pin']).to eq false
  end
end
