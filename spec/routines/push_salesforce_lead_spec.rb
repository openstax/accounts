require 'rails_helper'
require 'vcr_helper'

RSpec.describe PushSalesforceLead, vcr: VCR_OPTS do

  let!(:email_address) { FactoryBot.create(:email_address, value: 'f@f.com', verified: true) }
  let!(:user) { email_address.user }
  let!(:app) { FactoryBot.create :doorkeeper_application, lead_application_source: "Tutor Signup" }

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
                             subject: "",
                             source_application: app]

      expect(lead.errors).to be_empty
      expect(lead.id).not_to be_nil
      expect(lead.source).to eq "OSC Faculty"

      lead_from_sf = OpenStax::Salesforce::Remote::Lead.where(id: lead.id).first
      expect(lead_from_sf).not_to be_nil
      expect(lead_from_sf.application_source).to eq "Tutor Signup"
    end

    it 'allows nil source_application' do
      lead = described_class[user: user,
                             email: email_address.value,
                             role: "instructor",
                             school: "JP University",
                             using_openstax: "Confirmed Adoption Won",
                             url: "http://www.rice.edu",
                             newsletter: true,
                             phone_number: nil,
                             num_students: nil,
                             subject: "",
                             source_application: nil]

      expect(lead.errors).to be_empty
      expect(lead.id).not_to be_nil

      lead_from_sf = OpenStax::Salesforce::Remote::Lead.where(id: lead.id).first
      expect(lead_from_sf).not_to be_nil
      expect(lead_from_sf.application_source).to eq 'Accounts'
    end

    it "sends student record to Salesforce" do
      lead = described_class[user: user,
                             email: email_address.value,
                             role: "student",
                             school: "JP University",
                             using_openstax: "Confirmed Adoption Won",
                             url: "http://www.rice.edu",
                             newsletter: true,
                             phone_number: nil,
                             num_students: nil,
                             subject: "",
                             source_application: nil]

      expect(lead.errors).to be_empty
      expect(lead.id).not_to be_nil
      expect(lead.source).to eq "Student"

      lead_from_sf = OpenStax::Salesforce::Remote::Lead.where(id: lead.id).first
      expect(lead_from_sf).not_to be_nil
      expect(lead_from_sf.application_source).to eq 'Accounts'
    end
  end

end
