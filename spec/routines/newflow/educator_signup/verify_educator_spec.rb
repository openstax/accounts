require 'rails_helper'
require 'vcr_helper'

module Newflow
  module EducatorSignup

    RSpec.describe VerifyEducator, type: :routine do

      context 'when success' do
        subject(:routine) { described_class.call(verification_id: verification_id, user: user) }
        let!(:verification) { FactoryBot.create(:sheerid_verification, verification_id: verification_id, email: email_address) }
        let!(:user_email) { FactoryBot.create(:email_address, user: user, value: email_address, verified: true) }
        let(:app) { FactoryBot.create :doorkeeper_application, lead_application_source: "Tutor Signup" }
        let(:verification_id) { '5ef1ae416b29ca1badac1210' }
        let(:email_address) { 'bed1+bryan36dev@rice.edu' }
        let(:user) do
          FactoryBot.create(
            :user,
            state: 'activated', role: 'instructor', faculty_status: :pending_faculty,
            sheerid_reported_school: 'Bryan Eli University', first_name: 'Bryan', last_name: 'Eli',
            receive_newsletter: false, is_newflow: true, source_application: app
          )
        end

        xit 'works' do
          expect(routine.errors.any?).to be_falsey
        end
      end

    end

  end
end
