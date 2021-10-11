require 'rails_helper'
require 'vcr_helper'

RSpec.describe UpdateUserSalesforceLeadInfo, type: :routine, vcr: VCR_OPTS do
  before(:all) do
    @school = FactoryBot.create( :school, name: 'Morrisville State College', location: 'Domestic', type: 'College/University (4)')
    @user = FactoryBot.create(:user, self_reported_school: @school.name, salesforce_lead_id: '00Q4C000009iY0IUAU')
    VCR.use_cassette('UpdateUserSalesforceLeadInfo/sf_setup', VCR_OPTS) do
      @proxy = SalesforceProxy.new
      @proxy.setup_cassette
    end
  end

  context 'happy path' do
    it 'User has Lead with School, but not converted' do
      described_class.call
      @user.reload
      expect(@user.school_location).to eq 'domestic_school'
      expect(@user.school_type).to eq 'college'
    end

  end
end
