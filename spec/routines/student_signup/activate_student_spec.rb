require 'rails_helper'

module StudentSignup
  describe ActivateStudent, type: :routine  do
    context 'when success' do
      before do
        disable_sfdc_client
      end

      let(:user) do
        FactoryBot.create(:user, state: 'unverified', role: 'student', receive_newsletter: true)
      end

      it 'does NOT sign up user for the newsletter when NOT checked' do
        user.update(receive_newsletter: false)
        expect_any_instance_of(CreateSalesforceLead).not_to receive(:exec)
        described_class.call(user)
      end

      it 'pushes up to Salesforce the source application' do
        source_app = FactoryBot.create(:doorkeeper_application)
        user.update(source_application_id: source_app.id)

        expect_any_instance_of(CreateSalesforceLead).to receive(:exec)

        described_class.call(user)
      end
    end
  end
end
