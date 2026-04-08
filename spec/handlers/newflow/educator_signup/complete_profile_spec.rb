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

      context 'with valid params' do
        let(:params) do
          {
            signup: {
              books_used: books_used,
              books_used_details: books_used_details,
              using_openstax_how: using_openstax_how,
              educator_specific_role: educator_specific_role,
              school_name: 'Test School'
            }
          }
        end

        context 'with a different profile' do
          let(:params) do
            {
              signup: {
                school_name: 'School Name',
                books_of_interest: ['Test Book'],
                books_used: ['Test Book'],
                using_openstax_how: Newflow::EducatorSignup::CompleteProfile::AS_FUTURE,
                educator_specific_role: Newflow::EducatorSignup::CompleteProfile::INSTRUCTOR,
              }
            }
          end

          it "should not error" do
            result = handle
            expect(result.errors.count).to eq 0
          end
        end

        context 'DATA-297: student count on as_future path with feature flag enabled' do
          before do
            allow(Settings::FeatureFlags).to receive(:student_count_all_paths) { true }
          end

          let(:params) do
            {
              signup: {
                school_name: 'School Name',
                books_of_interest: ['Test Book'],
                using_openstax_how: Newflow::EducatorSignup::CompleteProfile::AS_FUTURE,
                educator_specific_role: Newflow::EducatorSignup::CompleteProfile::INSTRUCTOR,
                total_students_not_using: '42',
              }
            }
          end

          it "stores the standalone student count" do
            handle
            user.reload
            expect(user.how_many_students).to eq '42'
          end
        end

        context 'DATA-297: student count on as_recommending path with feature flag enabled' do
          before do
            allow(Settings::FeatureFlags).to receive(:student_count_all_paths) { true }
          end

          let(:params) do
            {
              signup: {
                school_name: 'School Name',
                books_of_interest: ['Test Book'],
                using_openstax_how: 'as_recommending',
                educator_specific_role: Newflow::EducatorSignup::CompleteProfile::INSTRUCTOR,
                total_students_not_using: '25',
              }
            }
          end

          it "stores the standalone student count" do
            handle
            user.reload
            expect(user.how_many_students).to eq '25'
          end
        end

        context 'DATA-297: student count on as_future path with feature flag disabled' do
          before do
            allow(Settings::FeatureFlags).to receive(:student_count_all_paths) { false }
          end

          let(:params) do
            {
              signup: {
                school_name: 'School Name',
                books_of_interest: ['Test Book'],
                using_openstax_how: Newflow::EducatorSignup::CompleteProfile::AS_FUTURE,
                educator_specific_role: Newflow::EducatorSignup::CompleteProfile::INSTRUCTOR,
                total_students_not_using: '99',
              }
            }
          end

          it "stores 0 when feature flag is off (no per-book details provided)" do
            handle
            user.reload
            expect(user.how_many_students).to eq '0'
          end
        end

        context 'DATA-297: as_primary path still calculates per-book total with feature flag enabled' do
          before do
            allow(Settings::FeatureFlags).to receive(:student_count_all_paths) { true }
          end

          it "calculates the correct total number of students from per-book details" do
            handle
            user.reload
            expect(user.how_many_students).to eq '14'
          end
        end

        context 'books used details' do
          let(:educator_specific_role) { Newflow::EducatorSignup::CompleteProfile::INSTRUCTOR }

          it "calculates the correct total number of students using books" do
            handle
            user.reload
            expect(user.how_many_students).to eq '14'
          end

          context 'filtering' do
            let(:books_used_details) do
              {
                "Book1" => { "num_students_using_book" => "5", "how_using_book" => "As core" },
                "Book2" => { "num_students_using_book" => "10", "how_using_book" => "As core" },
                "" => { "num_students_using_book" => "15", "how_using_book" => "As optional" },
                "Book3" => { "num_students_using_book" => "", "how_using_book" => "As optional" },
                "Book4" => { "num_students_using_book" => "20", "how_using_book" => "" }
              }
            end

            it "removes books with blank details" do
              handle
              user.reload
              expect(user.books_used_details).to eq({
                                     "Book1" => { "num_students_using_book" => "5", "how_using_book" => "As core" },
                                     "Book2" => { "num_students_using_book" => "10", "how_using_book" => "As core" }
                                   })
            end
          end
        end
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
