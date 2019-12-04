require 'rails_helper'

module Newflow
  RSpec.describe OauthCallback, type: :handler do
    before do
      load 'db/seeds.rb' # creates terms of use and privacy policy contracts
    end

    let(:email) { Faker::Internet.email }

    context 'when existing authentication found' do
      let(:request) {
        user = create_newflow_user(email)
        auth = FactoryBot.create(:authentication, user: user, provider: 'facebook')

        info = { email: email, name: Faker::Name.name }
        MockOmniauthRequest.new 'facebook', auth.uid, info
      }

      it 'simply outputs the user' do
        result = described_class.call(request: request)
        expect(result.outputs.user).to eq User.last
      end

      it 'creates a security log' do
        expect {
          described_class.call(request: request)
        }.to change(SecurityLog.where(event_type: :sign_in_successful), :count)
      end
    end

    context 'when no authentication found, but verified user found' do
      let(:request) {
        create_newflow_user(email)
        info = { email: email, name: Faker::Name.name }
        MockOmniauthRequest.new 'facebook', Faker::Internet.uuid, info
      }

      it 'creates an authentication' do
        expect {
          described_class.call(request: request)
        }.to change(Authentication, :count)
      end

      it 'transfers the authentication to the user' do
        expect_any_instance_of(TransferAuthentications).to receive(:call).and_call_original
        described_class.call(request: request)
      end

      it 'outputs the user' do
        result = described_class.call(request: request)
        expect(result.outputs.user).to eq User.last
      end

      it 'creates a security log' do
        expect {
          described_class.call(request: request)
        }.to change(SecurityLog.where(event_type: :sign_in_successful), :count)
      end
    end

    context 'when no authentication found, and no verified user found' do
      let(:request) {
        info = { email: email, name: Faker::Name.name }
        MockOmniauthRequest.new 'facebook', Faker::Internet.uuid, info
      }

      describe 'sign up a new user' do
        it 'creates a user' do
          expect {
            described_class.call(request: request)
          }.to change(User, :count)
        end

        it 'creates an authentication' do
          expect {
            described_class.call(request: request)
          }.to change(Authentication, :count)
        end

        it 'adds the user as a "lead" to salesforce'

        it 'creates a security log' do
          expect {
            described_class.call(request: request)
          }.to change(SecurityLog.where(event_type: :sign_up_successful), :count)
        end
      end
    end
  end
end
