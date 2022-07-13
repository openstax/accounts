require 'rails_helper'

describe EducatorProfile, type: :handler do
  let(:user) { create_user('user') }
  let(:handle) { described_class.handle( params: params, user: user) }
  let(:books_used) { ['Algebra and Trigonometry', 'Physics'] }
  let(:num_students_per_semester_taught) { 10 }
  let(:educator_specific_role) { 'instructor' }
  let(:using_openstax_how) { 'as_primary' }
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
  end

  context 'with invalid params' do
    context 'other must be filled out' do
      let(:educator_specific_role) { 'other' }

      it "should return correct error" do
        result = handle
        expect(result.errors.count).to eq 1
        expect(result.errors.first.message).to eq 'Please enter other role name'
      end
    end
  end
end
