require 'rails_helper'
require 'vcr_helper'

RSpec.describe AddAccountToSalesforceJob, type: :job, vcr: VCR_OPTS do
  before(:all) do
    VCR.use_cassette('AddAccountToSalesforceJob/sf_setup', VCR_OPTS) do
      @proxy = SalesforceProxy.new
      @proxy.setup_cassette
    end
  end

  xit "creates the OpenStax Account in Salesforce" do
    expect(Delayed::Job.count).to eq 0

    user = FactoryBot.create :user, role: User::INSTRUCTOR_ROLE
    AddAccountToSalesforceJob.new.perform(user.id)

    expect(Delayed::Job.count).to eq 1

    expect(user.salesforce_ox_account_id).to_not be nil
  end

end
