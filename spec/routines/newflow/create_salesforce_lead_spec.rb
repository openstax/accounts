require 'rails_helper'
require 'vcr_helper'

module Newflow
  RSpec.describe CreateSalesforceLead, type: :routine, vcr: VCR_OPTS do
    let!(:app) { FactoryBot.create :doorkeeper_application, lead_application_source: "Tutor Signup" }

    let!(:user_email) { FactoryBot.create(:email_address, user: user, value: email_address, verified: true) }
    let!(:user) do
      FactoryBot.create(
        :user, state: 'unverified', role: 'instructor', receive_newsletter: true, is_newflow: true, source_application: app
      )
    end
    let(:email_address) { 'f@f.com' }

    before(:all) do
      VCR.use_cassette('CreateSalesforceLead/sf_setup', VCR_OPTS) do
        @proxy = SalesforceProxy.new
        @proxy.setup_cassette
      end
    end

    it 'works on the happy path' do
      user.update!(source_application: app, role: :instructor)
      # expect(Rails.logger).not_to receive(:warn)

      lead = described_class.call(user: user).outputs.lead

      expect(user.salesforce_lead_id).not_to be_empty
      expect(user.errors).to be_empty

      expect(lead.errors).to be_empty
      expect(lead.id).not_to be_nil
      expect(lead.source).to eq "OSC Faculty"

      lead_from_sf = OpenStax::Salesforce::Remote::Lead.find(lead.id)
      expect(lead_from_sf).not_to be_nil
      expect(lead_from_sf.application_source).to eq "Tutor Signup"
    end

    xit 'allows nil source_application' do
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

    xit "sends student record to Salesforce" do
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
