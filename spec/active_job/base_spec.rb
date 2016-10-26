require 'rails_helper'

RSpec.describe ActiveJob::Base, type: :lib do
  subject(:job)         { described_class.new }
  let(:exception_class) { ActiveRecord::RecordNotFound }

  it 'triggers exception notifications on failure' do
    expect(job).to receive(:perform) { raise exception_class }
    expect(ExceptionNotifier).to receive(:notify_exception) do |exception, options|
      expect(exception).to be_a exception_class
    end

    expect{ job.perform_now }.to raise_error exception_class
  end
end
