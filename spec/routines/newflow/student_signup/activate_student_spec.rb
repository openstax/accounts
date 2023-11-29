require 'rails_helper'

module Newflow
  module StudentSignup
    describe ActivateStudent, type: :routine do
      context 'when success' do
        before do
          disable_sfdc_client
        end

        let(:source_app) { FactoryBot.create(:doorkeeper_application) }
        let(:user) do
          FactoryBot.create(
            :user, state: 'unverified', role: 'student',
            receive_newsletter: true, source_application: source_app
          )
        end

        it 'marks the user as activated' do
          expect(user.state).not_to eq(User::ACTIVATED)
          described_class.call(user: user)
          expect(user.state).to eq(User::ACTIVATED)
        end
      end
    end
  end
end
