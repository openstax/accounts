require 'rails_helper'

module Newflow
  module EducatorSignup
    describe ActivateAccount, type: :routine  do
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

        it 'creates a salesforce lead' do
          expect_any_instance_of(CreateSalesforceLead).to(
            receive(:exec).with(hash_including(user: user))
          )
          described_class.call(user: user)
        end
      end
    end
  end
end
