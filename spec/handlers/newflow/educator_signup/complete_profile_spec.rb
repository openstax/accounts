require 'rails_helper'

module Newflow
  module EducatorSignup
    describe CompleteProfile, type: :handler do
      let(:user) { create_user('user') }
      let(:handle) { described_class.handle( params: params, caller: user) }
      let(:books_used) { ['Algebra and Trigonometry', 'Physics'] }
      let(:subjects_of_interest) { ['Economics'] }
      let(:num_students_per_semester_taught) { 10 }
      let(:educator_specific_role) { 'instructor' }
      let(:using_openstax_how) { 'as_primary' }
      let(:params) do
        {
          signup: {
            books_used: books_used,
            subjects_of_interest: subjects_of_interest,
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
          let(:educator_specific_role) { Newflow::EducatorSignup::CompleteProfile::OTHER }

          it "should return correct error" do
            result = handle
            expect(result.errors.count).to eq 1
            expect(result.errors.first.message).to eq 'Please enter other role name'
          end
        end

        context 'books used must be filled out' do
          let(:educator_specific_role) { Newflow::EducatorSignup::CompleteProfile::INSTRUCTOR }
          let(:using_openstax_how) { Newflow::EducatorSignup::CompleteProfile::AS_PRIMARY }
          let(:books_used) { [] }

          it "should return correct error" do
            result = handle
            expect(result.errors.count).to eq 1
            expect(result.errors.first.message).to eq 'Please enter books used'
          end
        end

        context 'subjects of interest must be filled out' do
          let(:educator_specific_role) { Newflow::EducatorSignup::CompleteProfile::INSTRUCTOR }
          let(:using_openstax_how) { Newflow::EducatorSignup::CompleteProfile::AS_FUTURE }
          let(:subjects_of_interest) { [] }

          it "should return correct error" do
            result = handle
            expect(result.errors.count).to eq 1
            expect(result.errors.first.message).to eq 'Please enter subjects of interest'
          end
        end

        context 'number of students taught must be filled out' do
          let(:educator_specific_role) { Newflow::EducatorSignup::CompleteProfile::INSTRUCTOR }
          let(:num_students_per_semester_taught) { nil }

          it "should return correct error" do
            result = handle
            expect(result.errors.count).to eq 1
            expect(result.errors.first.message).to eq 'Please enter number of students taught'
          end
        end
      end

      context 'when success' do
        context 'salesforce' do
          it 'calls UpdateSalesforceLead' do
            skip 'TODO'
            expect_any_instance_of(UpdateSalesforceLead).to receive(:exec).with(user: user)
            handle
          end
        end
      end
    end
  end
end
