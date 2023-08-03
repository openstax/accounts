require 'rails_helper'

module Newflow
  module EducatorSignup

    describe CompleteProfile, type: :handler do
      let(:user) { create_user('user') }
      let(:handle) { described_class.handle( params: params, user: user) }
      let(:books_used) { ['Algebra and Trigonometry', 'Physics'] }
      let(:books_used_details) {
        {
          "Algebra and Trigonometry" => {
            "num_students_using_book" => "12",
            "how_using_book" => "As the core textbook for my course"
          },
          "Physics" => {
            "num_students_using_book" => "2",
            "how_using_book" => "As an optional/recommended textbook for my course"
          }
        }
      }
      let(:educator_specific_role) { 'instructor' }
      let(:using_openstax_how) { Newflow::EducatorSignup::CompleteProfile::AS_PRIMARY }
      let(:params) do
        {
          signup: {
            books_used: books_used,
            books_used_details: books_used_details,
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
            expect(result.errors.count).to eq 2
            expect(result.errors.first.message).to eq 'Please enter school name'
          end
        end

        context 'books used must be filled out' do
          let(:educator_specific_role) { Newflow::EducatorSignup::CompleteProfile::INSTRUCTOR }
          let(:using_openstax_how) { Newflow::EducatorSignup::CompleteProfile::AS_PRIMARY }
          let(:books_used) { [] }

          it "should return correct error" do
            result = handle
            expect(result.errors.count).to eq 2
            expect(result.errors.first.message).to eq 'Please enter school name'
          end
        end

        context 'books used details must be filled out' do
          let(:params) do
            {
              signup: {
                school_name: 'School Name',
                books_used: ['Test Book'],
                books_used_details: {},
                using_openstax_how: Newflow::EducatorSignup::CompleteProfile::AS_PRIMARY,
                educator_specific_role: Newflow::EducatorSignup::CompleteProfile::INSTRUCTOR,
              }
            }
          end

          it "should return correct error" do
            result = handle
            expect(result.errors.count).to eq 1
            expect(result.errors.first.message).to eq 'Please enter the number of students taught and how the book is used'
          end
        end
      end
    end
  end
end
