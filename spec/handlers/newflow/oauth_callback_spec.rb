require 'rails_helper'

module Newflow
  RSpec.describe OauthCallback, type: :handler do
    before(:all) do
      load 'db/seeds.rb' # creates terms of use and privacy policy contracts
    end

    let(:email) { Faker::Internet.email }

    context 'when existing authentication found' do
      let(:info) {
        { email: email, name: Faker::Name.name }
      }

      let(:user) {
        create_newflow_user(email)
      }

      let(:auth) {
        FactoryBot.create(:authentication, user: user, provider: 'facebook')
      }

      let(:request) {
        MockOmniauthRequest.new 'facebook', auth.uid, info
      }

      let(:subject) {
        described_class.call(request: request)
      }

      it 'simply outputs the user' do
        expect(subject.outputs.user).to eq User.last
      end
    end

    context 'when no authentication found, but verified user found' do
      before do
        create_newflow_user(email)
      end

      let(:info) {
        { email: email, name: Faker::Name.name }
      }

      let(:request) {
        MockOmniauthRequest.new 'facebook', Faker::Internet.uuid, info
      }

      let(:subject) {
        described_class.call(request: request)
      }

      it 'creates an authentication' do
        expect {
          subject
        }.to change(Authentication, :count)
      end

      it 'transfers the authentication to the user' do
        expect_any_instance_of(TransferAuthentications).to receive(:call).and_call_original
        subject
      end

      it 'outputs the user' do
        expect(subject.outputs.user).to eq User.last
      end
    end

    context 'when no authentication found, and no verified user found' do
      let(:info) {
        { email: email, name: Faker::Name.name }
      }

      let(:request) {
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

        it 'creates an email address as verified' do
          expect {
            described_class.call(request: request)
          }.to change { EmailAddress.where(verified: true).count }
        end
      end
    end

    context 'when authentication found, but the response from social provider does not include email' do
      before do
        create_newflow_user(email)
      end

      let(:info) {
        { email: nil, name: Faker::Name.name }
      }

      let(:request) {
        MockOmniauthRequest.new 'facebook', Faker::Internet.uuid, info
      }

      let(:subject) {
        described_class.call(request: request)
      }

      it 'processes the omniauth request without error' do
        expect(subject.outputs.user).to eq User.last
      end
    end
  end
end
