require 'rails_helper'
require 'vcr_helper'

RSpec.describe CreateSalesforceLead, type: :routine, vcr: VCR_OPTS do

  before(:all) do
    VCR.use_cassette('CreateSalesforceLead/sf_setup', VCR_OPTS) do
      @proxy = SalesforceProxy.new
      @proxy.setup_cassette
    end
  end


  let!(:school) { FactoryBot.create :school,
                                    salesforce_id: '0010B000021QuAyQAK',
                                    name: 'Test University'
  }

  let!(:user1) { FactoryBot.create :user,
                                   role: User::INSTRUCTOR_ROLE,
                                   faculty_status: User::PENDING_FACULTY,
                                   school: school
  }

  it 'works on the happy path' do
    lead = described_class.call(user_id: user1.id)
    expect(Rails.logger).not_to receive(:warn)
    expect(lead.errors).to be_empty
  end
end
