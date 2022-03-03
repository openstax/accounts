require 'rails_helper'
require 'vcr_helper'

RSpec.describe UpdateUserContactInfo, type: :routine, vcr: VCR_OPTS do
  before(:all) do
    VCR.use_cassette('UpdateUserContactInfo/sf_setup', VCR_OPTS ) do
      @proxy = SalesforceProxy.new
      @proxy.setup_cassette
    end
  end

  let!(:user) { FactoryBot.create :user, role: User::INSTRUCTOR_ROLE, faculty_status: User::PENDING_FACULTY }

  xit "uploads a users data to Salesforce and updates the contact ID" do
    expect(user.salesforce_contact_id).to eq nil
    described_class.call

    user.reload
    expect(user.salesforce_contact_id).to_not eq nil
  end
end
