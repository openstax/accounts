require 'rails_helper'

module Newflow
  describe EducatorCompleteProfile, type: :handler do
    let(:handle) { described_class.handle( params.merge(caller: user)) }
    let(:books_used) { ['Algebra and Trigonometry', 'Physics'] }
    let(:subjects_of_interest) { ['Economics'] }
    let(:num_students_per_semester_taught) { 10 }
    let(:educator_specific_role) { 'instructor' }
    let(:using_openstax_how) { 'as_primary' }
    let(:params) do {
      params: {
        signup: {
          books_used: books_used,
          subjects_of_interest: subjects_of_interest,
          num_students_per_semester_taught: num_students_per_semester_taught,
          using_openstax_how: using_openstax_how,
          educator_specific_role: educator_specific_role,
        }
      }
    }
    end
    let(:user) do
      create_user('user').tap do |uu|
        uu.update_attribute(:state, User::EDUCATOR_INCOMPLETE_PROFILE)
      end
    end

    before(:each) do
      disable_sfdc_client
      allow(Settings::Salesforce).to receive(:push_leads_enabled) { true }
    end

    context 'with invalid params' do
      context 'other must be filled out' do
        let(:educator_specific_role) { Newflow::EducatorCompleteProfile::OTHER }

        it "should return correct error" do
          result = handle
          expect(result.errors.count).to eq 1
          expect(result.errors.first.message).to eq 'Please enter other role name'
        end
      end

      context 'books used must be filled out' do
        let(:educator_specific_role) { Newflow::EducatorCompleteProfile::INSTRUCTOR }
        let(:using_openstax_how) { Newflow::EducatorCompleteProfile::AS_PRIMARY }
        let(:books_used) { [] }

        it "should return correct error" do
          result = handle
          expect(result.errors.count).to eq 1
          expect(result.errors.first.message).to eq 'Please enter books used'
        end
      end

      context 'subjects of interest must be filled out' do
        let(:educator_specific_role) { Newflow::EducatorCompleteProfile::INSTRUCTOR }
        let(:using_openstax_how) { Newflow::EducatorCompleteProfile::AS_FUTURE }
        let(:subjects_of_interest) { [] }

        it "should return correct error" do
          result = handle
          expect(result.errors.count).to eq 1
          expect(result.errors.first.message).to eq 'Please enter subjects of interest'
        end
      end
    end

    context 'when success' do
      it "updates the user and switches state to educator complete profile" do
        result = handle
        user.reload
        expect(user.state).to eq(User::EDUCATOR_COMPLETE_PROFILE)
        expect(result.errors.count).to eq 0
      end

      context "salesforce lead gets pushed" do
        it "sends the subject properly formatted" do
          expect_lead_push(subject: "Algebra and Trigonometry;Physics")
          handle
        end
      end
    end

    def expect_lead_push(options={})
      expect_any_instance_of(PushSalesforceLead).to receive(:exec).with(hash_including(options))
    end
  end
end
