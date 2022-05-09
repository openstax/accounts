require 'rails_helper'

module EducatorSignup

  describe CompleteProfile, type: :handler do
    let(:email) { 'openstax@example.com' }
    let(:user) { create_user(email) }
    let(:handle) { described_class.handle( params: params, user: user) }
    before(:each) do
      disable_sfdc_client
    end

    context 'with invalid params' do
      context 'other must be filled out' do
        let(:params) do
          {
            signup: {
              books_used: ['Algebra and Trigonometry', 'Physics'],
              num_students_per_semester_taught: [10, 15],
              using_openstax_how: :as_primary,
              educator_specific_role: :other,
            }
          }
        end

        it "should return correct error" do
          result = handle
          expect(result.errors.count).to eq 1
          expect(result.errors.first.message).to eq 'Please enter other role name'
        end
      end

      context 'books used must be filled out' do
        let(:params) do
          {
            signup: {
              books_of_interest: [],
              num_students_per_semester_taught: [10, 15],
              using_openstax_how: :as_primary,
              educator_specific_role: :instructor,
            }
          }
        end

        it "should return correct error" do
          result = handle
          expect(result.errors.count).to eq 1
          expect(result.errors.first.message).to eq 'Please enter books of interest'
        end
      end

      context 'number of students taught must be filled out' do
        let(:params) do
          {
            signup: {
              books_of_interest: ['Algebra and Trigonometry', 'Physics'],
              num_students_per_semester_taught: [],
              using_openstax_how: :as_primary,
              educator_specific_role: :instructor,
            }
          }
        end

        it "should return correct error" do
          result = handle
          expect(result.errors.count).to eq 1
          expect(result.errors.first.message).to eq 'Please enter number of students taught'
        end
      end
    end
  end
end
