require 'rails_helper'
require 'vcr_helper'

module Newflow
  RSpec.describe UpdateSalesforceLead, vcr: VCR_OPTS do
    subject(:routine_call) { described_class.call(user: user) }

    let!(:user_email) { FactoryBot.create(:email_address, user: user, value: email_address, verified: true) }
    let(:app) { FactoryBot.create :doorkeeper_application, lead_application_source: "Tutor Signup" }
    let(:create_initial_lead) { CreateSalesforceLead.call(user: user).outputs.lead }
    let(:email_address) { 'f@f.com' }
    let(:user) do
      FactoryBot.create(
        :user,
        first_name: 'initial', last_name: 'initial',
        state: 'activated', role: 'instructor', faculty_status: :pending_faculty,
        sheerid_reported_school: 'not known yet', is_newflow: true,
        receive_newsletter: false, source_application: app
      )
    end

    before(:all) do
      VCR.use_cassette('Newflow_UpdateSalesforceLead/sf_setup', VCR_OPTS) do
        @proxy = SalesforceProxy.new
        @proxy.setup_cassette
      end
    end

    before do
      expect(create_initial_lead.errors.any?).to be_falsey
      expect(user.salesforce_lead_id).to be_present
      user.update(first_name: 'updated', last_name: 'updated')
    end

    context 'without a School' do
      it 'works' do
        routine_call
        expect(routine_call.errors.any?).to be_falsey
        expect(routine_call.outputs.lead.first_name).to eq('updated')
        expect(routine_call.outputs.lead.last_name).to eq('updated')
        expect(routine_call.outputs.lead.school).to eq 'not known yet'
        expect(routine_call.outputs.lead.city).to be_nil
        expect(routine_call.outputs.lead.state).to be_nil
        expect(routine_call.outputs.lead.state_code).to be_nil
      end
    end

    context 'with a School with a State abbreviation' do
      let(:school) { FactoryBot.create :school, state: 'TX' }

      before { user.update_attribute :school, school }

      it 'works' do
        expect_any_instance_of(OpenStax::Salesforce::Remote::Lead).to receive(:update) do |_, hash|
          expect(hash[:school]).to eq school.name
          expect(hash[:city]).to eq school.city
          expect(hash[:state]).to be_nil
          expect(hash[:state_code]).to eq school.state
        end

        routine_call
        expect(routine_call.errors.any?).to be_falsey
      end
    end

    context 'with a School with a full State name' do
      let(:school) { FactoryBot.create :school, state: 'Texas' }

      before { user.update_attribute :school, school }

      it 'works' do
        expect_any_instance_of(OpenStax::Salesforce::Remote::Lead).to receive(:update) do |_, hash|
          expect(hash[:school]).to eq school.name
          expect(hash[:city]).to eq school.city
          expect(hash[:state]).to eq school.state
          expect(hash[:state_code]).to be_nil
        end

        routine_call
        expect(routine_call.errors.any?).to be_falsey
      end
    end
  end
end
