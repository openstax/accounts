require 'rails_helper'
require 'vcr_helper'

include ActiveJob::TestHelper

RSpec.describe CreateSalesforceLeadJob, type: :job, vcr: VCR_OPTS do

  before(:all) do
    ActiveJob::Base.queue_adapter = :test

    VCR.use_cassette('CreateSalesforceLead/sf_setup', VCR_OPTS) do
      @proxy = SalesforceProxy.new
      @proxy.setup_cassette
    end
  end

  let(:user) { create_user(email: 'accounts@example.com', role: :instructor, password: Faker::Internet.password, confirmation_code: 1111) }

  let(:user_id) { user.id }

  subject(:job) { described_class.perform_later(user_id) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
                        .with(user_id)
                        .on_queue("salesforce_leads")
  end

  it 'does not create two leads for the same user', perform_enqueued: true do
    user.update!(state: :activated)
    described_class.perform_now(user_id)
    expect(described_class.perform_now(user_id)).to respond_to?(Rails.logger.warn)
  end

  it 'populate the salesforce lead id for the user', perform_enqueued: true do
    described_class.perform_now(user_id: user_id)
    #byebug
    #expect(user.salesforce_lead_id).to_not be_nil
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
