require 'rails_helper'
require 'vcr_helper'

module Newflow
  RSpec.describe VerifyEducator, type: :routine, vcr: VCR_OPTS do
    context 'when success' do
      subject(:routine) { described_class.call(verification_id: verification_id, user: user) }
      let!(:verification) { FactoryBot.create(:sheerid_verification, verification_id: verification_id, email: email_address) }
      let!(:user_email) { FactoryBot.create(:email_address, user: user, value: email_address, verified: true) }
      let(:app) { FactoryBot.create :doorkeeper_application, lead_application_source: "Tutor Signup" }
      let(:verification_id) { '5ef1ae416b29ca1badac1210' }
      let(:existing_lead) { CreateSalesforceLead.call(user: user).outputs.lead }
      let(:email_address) { 'f@f.com' }
      let(:user) do
        FactoryBot.create(
          :user,
          state: 'activated', role: 'instructor', faculty_status: :pending_faculty,
          sheerid_reported_school: 'Bryan Eli University', first_name: 'Bryan', last_name: 'Eli',
          receive_newsletter: false, is_newflow: true, source_application: app
        )
      end

      before(:all) do
        VCR.use_cassette('VerifyEducator/sf_setup', VCR_OPTS) do
          @proxy = SalesforceProxy.new
          @proxy.setup_cassette
        end
      end

      it 'works' do
        expect(existing_lead.errors.any?).to be_falsey
        expect(user.salesforce_lead_id).to be_present

        expect(routine.errors.any?).to be_falsey
      end
    end
  end
end
