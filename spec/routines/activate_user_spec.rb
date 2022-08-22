require 'rails_helper'

RSpec.describe ActivateUser do
  context 'student'  do
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

  context 'instructor'  do
    context 'when success' do
      before do
        disable_sfdc_client
      end

      let(:source_app) { FactoryBot.create(:doorkeeper_application) }
      let(:user) do
        FactoryBot.create(
          :user, state: 'unverified', role: 'instructor',
          receive_newsletter: true, source_application: source_app
        )
      end

      it 'marks the user as activated' do
        expect(user.state).not_to eq('activated')
        described_class.call(user)
        expect(user.state).to eq('activated')
      end
    end
  end
end
