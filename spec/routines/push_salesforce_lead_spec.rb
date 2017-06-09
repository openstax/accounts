require 'rails_helper'
require 'vcr_helper'

RSpec.describe PushSalesforceLead, vcr: VCR_OPTS do

  let!(:email_address) { FactoryGirl.create(:email_address, value: 'f@f.com', verified: true) }
  let!(:user) { email_address.user }

  context "connected to Salesforce" do
    before(:each) { load_salesforce_user }

    it 'works on the happy path' do
      expect(Rails.logger).not_to receive(:warn)

      lead = described_class[user: user,
                             email: email_address.value,
                             role: "instructor",
                             school: "JP University",
                             using_openstax: "Confirmed Adoption Won",
                             url: "http://www.rice.edu",
                             newsletter: true,
                             phone_number: nil,
                             num_students: nil,
                             subject: ""]

      expect(lead.errors).to be_empty
      expect(lead.id).not_to be_nil
      expect(lead.source).to eq "OSC Faculty"

      lead_from_sf = OpenStax::Salesforce::Remote::Lead.where(id: lead.id).first
      expect(lead_from_sf).not_to be_nil
    end
  end

  it "raises an exception when role is student" do
    expect{
      described_class[user: user,
                      email: email_address.value,
                      role: "student",
                      school: "JP University",
                      using_openstax: "Confirmed Adoption Won",
                      url: "http://www.rice.edu",
                      newsletter: true,
                      phone_number: nil,
                      num_students: nil,
                      subject: ""]
    }.to raise_error(IllegalArgument)
  end

end
