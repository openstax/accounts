require 'rails_helper'
require 'vcr_helper'

module Newflow
  describe CreateSalesforceLead, type: :routine, vcr: VCR_OPTS do

    before(:all) do
      VCR.use_cassette('Newflow_CreateSalesforceLead/sf_setup', VCR_OPTS) do
        @proxy = SalesforceProxy.new
        @proxy.setup_cassette
      end
    end

    before(:each) do
      FactoryBot.create(:email_address, user: user, value: email_value, verified: true)
    end

    let!(:routine_call) { described_class.call(user: user) }
    let(:lead) { routine_call.outputs.lead }
    let(:app) { FactoryBot.create :doorkeeper_application, lead_application_source: "Tutor Signup" }
    let(:user) do
      FactoryBot.create(
        :user, state: User::UNVERIFIED, role: User::INSTRUCTOR_ROLE, faculty_status: User::PENDING_FACULTY,
        receive_newsletter: false, is_newflow: true, source_application: app
      )
    end
    let(:email_value) { 'f@f.com' }
    let(:sf_lead_by_id) { OpenStax::Salesforce::Remote::Lead.find_by(accounts_uuid: user.uuid) }

    context 'on success' do
      it 'creates a lead which can be found by ID' do
        expect(sf_lead_by_id).not_to be_nil
      end

      it 'stores the application source' do
        expect(sf_lead_by_id.application_source).to eq "Tutor Signup"
      end

      it 'updates the salesforce lead id' do
        expect(user.salesforce_lead_id).not_to be_blank
      end

      example 'user has no errors' do
        expect(user.errors).to be_empty
      end

      example 'lead has no errors' do
        expect(lead.errors).to be_empty
      end

      it 'sets the lead id' do
        expect(lead.id).not_to be_nil
      end

      it 'sets the lead source' do
        expect(lead.source).to eq "Instructor Verification"
      end
    end

  end
end
