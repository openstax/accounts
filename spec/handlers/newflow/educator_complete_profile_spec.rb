require 'rails_helper'

module Newflow
  describe EducatorCompleteProfile, type: :handler do
    before(:each) do
      disable_sfdc_client
      allow(Settings::Salesforce).to receive(:push_leads_enabled) { true }
    end

    let(:user) do
      create_user('user').tap do |uu|
        uu.update_attribute(:state, User::EDUCATOR_INCOMPLETE_PROFILE)
      end
    end

    context 'when success' do
      it "updates the user and switches state to educator complete profile" do
        handle
        user.reload
        expect(user.state).to eq(User::EDUCATOR_COMPLETE_PROFILE)
      end

      context "salesforce lead gets pushed" do
        it "sends the subject properly formatted" do
          expect_lead_push(subject: "Algebra and Trigonometry;Physics")
          handle
        end
      end
    end

    def handle(books_used: ["Algebra and Trigonometry", "Physics"], num_students_per_semester_taught: "30", using_openstax_how: "as_primary", educator_specific_role: 'instructor')
      described_class.handle(
        params: {
          signup: {
            books_used: books_used,
            num_students_per_semester_taught: num_students_per_semester_taught,
            using_openstax_how: using_openstax_how,
            educator_specific_role: educator_specific_role,
          }
        },
        caller: user,
      )
    end

    def expect_lead_push(options={})
      expect_any_instance_of(PushSalesforceLead).to receive(:exec).with(hash_including(options))
    end
  end
end
