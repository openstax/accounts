require 'rails_helper'

module EducatorSignup

  describe CompleteProfile, type: :handler do
    let(:email) { Faker::Internet.email }
    let(:user) { create_user(email) }
    let(:handle) { described_class.handle( params: params, user: user) }
    let(:books_used) { ['Algebra and Trigonometry', 'Physics'] }
    let(:num_students_per_semester_taught) { 10 }
    let(:educator_specific_role) { 'instructor' }
    let(:using_openstax_how) { EducatorSignup::CompleteProfile::AS_PRIMARY }
    let(:params) do
      {
        signup: {
          books_used: books_used,
          num_students_per_semester_taught: num_students_per_semester_taught,
          using_openstax_how: using_openstax_how,
          educator_specific_role: :instructor,
        }
      }
    end

    before(:each) do
      disable_sfdc_client
    end

    context 'with invalid params' do
      context 'other must be filled out' do
        let(:educator_specific_role) { :other }

        it "should return correct error" do
          result = handle
          expect(result.errors.count).to eq 1
          expect(result.errors.first.message).to eq 'Please enter other role name'
        end
      end

      context 'books used must be filled out' do
        let(:educator_specific_role) { :instructor }
        let(:using_openstax_how) { :as_primary }
        let(:books_used) { [] }

        it "should return correct error" do
          result = handle
          expect(result.errors.count).to eq 1
          expect(result.errors.first.message).to eq 'Please enter books used'
        end
      end

      context 'number of students taught must be filled out' do
        let(:educator_specific_role) { :instructor }
        let(:num_students_per_semester_taught) { nil }

        it "should return correct error" do
          result = handle
          expect(result.errors.count).to eq 1
          expect(result.errors.first.message).to eq 'Please enter number of students taught'
        end
      end
    end
  end
end
