require 'rails_helper'

module Newflow
  describe ActivateUser, type: :routine  do
    context 'when success' do
      before do
        disable_sfdc_client
        allow(Settings::Salesforce).to receive(:push_leads_enabled).and_return(true)
      end

      let(:user) do
        FactoryBot.create(:user, state: 'unverified', role: 'student', receive_newsletter: true)
      end

      it 'marks the user as activated' do
        expect(user.state).not_to eq('activated')
        described_class.call(user)
        expect(user.state).to eq('activated')
      end

      it 'signs up user for the newsletter when checked' do
        expect_any_instance_of(PushSalesforceLead).to(
          receive(:exec).with(hash_including(newsletter: true))
        )
        described_class.call(user)
      end

      it 'does NOT sign up user for the newsletter when NOT checked' do
        user.update_attributes(receive_newsletter: false)
        expect_any_instance_of(PushSalesforceLead).to receive(:exec).with(hash_including({ newsletter: false }))
        described_class.call(user)
      end

      it 'pushes up to Salesforce the source application' do
        source_app = FactoryBot.create(:doorkeeper_application)
        user.update_attributes(source_application_id: source_app.id)

        expect_any_instance_of(PushSalesforceLead).to(
          receive(:exec).with(hash_including(source_application: source_app))
        )
        described_class.call(user)
      end
    end

    context 'when failure' do
      # TODO
    end
  end
end
