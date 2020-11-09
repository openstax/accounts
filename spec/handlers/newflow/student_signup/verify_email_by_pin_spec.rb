require 'rails_helper'
require 'vcr_helper'

module Newflow
  module StudentSignup
    describe VerifyEmailByPin, type: :handler, vcr: VCR_OPTS do
      before(:all) do
        VCR.use_cassette('handlers/newflow/student_signup/sf_setup', VCR_OPTS) do
          @proxy = SalesforceProxy.new
          @proxy.setup_cassette
        end
      end

      context 'when success' do
        let(:user) do
          FactoryBot.create(:user, state: 'unverified', source_application: source_app, receive_newsletter: true)
        end

        let(:source_app) do
          FactoryBot.create(:doorkeeper_application)
        end

        let(:email) do
          FactoryBot.create(:email_address, user: user)
        end

        let(:params) do
          {
            confirm: {
              pin: email.confirmation_pin
            }
          }
        end

        it 'runs ActivateStudent' do
          expect_any_instance_of(ActivateStudent).to receive(:exec)
          described_class.call(params: params, email_address: email)
        end

        it 'sets the user (email owner) state to "activated"' do
          expect(email.user.state).not_to eq('activated')
          described_class.call(params: params, email_address: email)
          expect(email.user.state).to eq('activated')
        end

        it 'marks the user-s EmailAddress as verified' do
          expect(email.verified).to be(false)
          described_class.call(params: params, email_address: email)
          expect(email.verified).to be(true)
        end
      end
    end
  end
end
