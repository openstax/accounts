require 'rails_helper'

module Newflow
  module InstructorSignup

    describe CompleteProfile, type: :handler do
      let(:user) { create_user('user') }
      let(:handle) { described_class.handle( params: params, user: user) }
      let(:books_used) { ['Algebra and Trigonometry', 'Physics'] }
      let(:num_students_per_semester_taught) { 10 }
      let(:educator_specific_role) { 'instructor' }
      let(:using_openstax_how) { Newflow::InstructorSignup::CompleteProfile::AS_PRIMARY }
      let(:params) do
        {
          signup: {
            books_used: books_used,
            num_students_per_semester_taught: num_students_per_semester_taught,
            using_openstax_how: using_openstax_how,
            educator_specific_role: educator_specific_role,
          }
        }
      end

      before(:each) do
        disable_sfdc_client
        allow(Settings::Salesforce).to receive(:push_leads_enabled) { true }
      end

      context 'with invalid params' do
        context 'other must be filled out' do
          let(:educator_specific_role) { Newflow::InstructorSignup::CompleteProfile::OTHER }

          it "should return correct error" do
            result = handle
            expect(result.errors.count).to eq 2
            expect(result.errors.first.message).to eq 'Please enter school name'
          end
        end

        context 'books used must be filled out' do
          let(:educator_specific_role) { Newflow::InstructorSignup::CompleteProfile::INSTRUCTOR }
          let(:using_openstax_how) { Newflow::InstructorSignup::CompleteProfile::AS_PRIMARY }
          let(:books_used) { [] }

          it "should return correct error" do
            result = handle
            expect(result.errors.count).to eq 2
            expect(result.errors.first.message).to eq 'Please enter school name'
          end
        end

        context 'number of students taught must be filled out' do
          let(:educator_specific_role) { Newflow::InstructorSignup::CompleteProfile::INSTRUCTOR }
          let(:num_students_per_semester_taught) { nil }

          it "should return correct error" do
            result = handle
            expect(result.errors.count).to eq 2
            expect(result.errors.first.message).to eq 'Please enter school name'
          end
        end
      end
    end
  end
end