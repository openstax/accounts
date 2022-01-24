require 'rails_helper'
require 'vcr_helper'

RSpec.describe UpdateUserContactInfo, type: :routine, vcr: VCR_OPTS do
  before(:all) do
    VCR.use_cassette('UpdateUserContactInfo/sf_setup', VCR_OPTS ) do
      @proxy = SalesforceProxy.new
      @proxy.setup_cassette
    end
  end

  let!(:user) { FactoryBot.create :user, role: User::INSTRUCTOR_ROLE, faculty_status: User::PENDING_FACULTY, uuid: '1a48905c-b67a-440a-9b3a-60368c3a4bf7' }

  it "users with contact modified within number of days in Settings" do
    expected_date = DateTime.strptime("2022-01-14", '%Y-%m-%d')
    expect(DateTime).to receive(:strptime).and_return(expected_date)

    expect(user.salesforce_contact_id).to eq nil
    UpdateUserContactInfo.call
    user.reload
    expect(user.salesforce_contact_id).to eq '0034C00000XQDaCQAX'
  end
end