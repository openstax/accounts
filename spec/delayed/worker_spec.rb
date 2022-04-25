require 'rails_helper'

RSpec.describe Delayed::Worker, type: :lib do
  let(:job)                { ::ActiveJob::Base.new }
  let(:delayed_job)        { ::Delayed::Job.create!(payload_object: job) }
  subject(:delayed_worker) { described_class.new }

  context 'exceptions with no argument' do
    [
      ActiveRecord::RecordNotFound,
      Addressable::URI::InvalidURIError,
      ArgumentError,
      JSON::ParserError,
      NameError,
      NoMethodError,
      NotYetImplemented,
      ActiveJob::DeserializationError
    ].each do |exception|
      context exception.name do
        it 'fails the job instantly' do
          expect(job).to receive(:perform) { raise exception }

          expect(delayed_job.failed?).to eq false
          delayed_worker.run(delayed_job)
          expect(delayed_job.failed?).to eq true
        end
      end
    end
  end

  context 'exceptions with arguments' do
    context 'ActiveRecord::RecordInvalid' do
      let(:exception) { ActiveRecord::RecordInvalid }

      it 'fails the job instantly' do
        expect(job).to receive(:perform) { raise exception, User.new }

        expect(delayed_job.failed?).to eq false
        delayed_worker.run(delayed_job)
        expect(delayed_job.reload.failed?).to eq true
      end
    end

    context 'OAuth2::Error' do
      let(:exception) { OAuth2::Error }

      it 'fails the job instantly if it is a 400 status' do
        expect(job).to receive(:perform) { raise exception, {status: 404} }

        expect(delayed_job.failed?).to eq false
        delayed_worker.run(delayed_job)
        expect(delayed_job.reload.failed?).to eq true
      end

      it 'does not fail the job instantly if it is a 500 status' do
        expect(job).to receive(:perform) { raise exception, {status: 504} }

        expect(delayed_job.failed?).to eq false
        delayed_worker.run(delayed_job)
        expect(delayed_job.reload.failed?).to eq false
      end

      it 'does not fail the job instantly if it is an unknown status' do
        expect(job).to receive(:perform) { raise exception, {status: 0} }

        expect(delayed_job.failed?).to eq false
        delayed_worker.run(delayed_job)
        expect(delayed_job.reload.failed?).to eq false
      end
    end

    context 'OpenURI::HTTPError' do
      let(:exception) { OpenURI::HTTPError }

      it 'fails the job instantly if it is a 400 status' do
        expect(job).to receive(:perform) { raise exception.new('404 Not Found', {}) }

        expect(delayed_job.failed?).to eq false
        delayed_worker.run(delayed_job)
        expect(delayed_job.reload.failed?).to eq true
      end

      it 'does not fail the job instantly if it is a 500 status' do
        expect(job).to receive(:perform) {
          raise exception.new('504 Gateway Timeout', {})
        }

        expect(delayed_job.failed?).to eq false
        delayed_worker.run(delayed_job)
        expect(delayed_job.reload.failed?).to eq false
      end

      it 'does not fail the job instantly if it is an unknown status' do
        expect(job).to receive(:perform) { raise exception.new('', {}) }

        expect(delayed_job.failed?).to eq false
        delayed_worker.run(delayed_job)
        expect(delayed_job.reload.failed?).to eq false
      end
    end

    context 'RuntimeError' do
      it 'does not fail the job instantly' do
        expect(job).to receive(:perform) { raise 'Some Error' }

        expect(delayed_job.failed?).to eq false
        delayed_worker.run(delayed_job)
        expect(delayed_job.reload.failed?).to eq false
      end
    end
  end
end
