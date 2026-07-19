require 'rails_helper'

module Newflow
  module LearnerSignup
    describe SignupForm, type: :handler do
      context 'when success' do
        before(:all) do
          DatabaseCleaner.start
          load('db/seeds.rb')
        end

        after(:all) { DatabaseCleaner.clean }

        let(:handler_call) do
          described_class.call(params: params)
        end

        let(:params) do
          {
            signup: {
              email: email,
              password: Faker::Internet.password(min_length: 8),
              newsletter: true,
              contract_1_id: FinePrint::Contract.first.id,
              contract_2_id: FinePrint::Contract.second.id
            }
          }
        end

        let(:email) do
          Faker::Internet.email
        end

        it 'creates an (unverified) user tagged as a self-learner, not a student' do
          expect { handler_call }.to change {
            User.where(state: 'unverified', role: 'self_learner').count
          }
          expect(User.last).not_to be_student
        end

        it 'does not require (or set) a first or last name' do
          handler_call
          user = User.last
          expect(user.first_name).to be_blank
          expect(user.last_name).to be_blank
        end

        it 'does not require a school' do
          handler_call
          expect(User.last.school).to be_nil
        end

        it 'creates an identity' do
          expect { handler_call }.to change { Identity.count }
        end

        it 'creates an authentication with provider = identity' do
          expect { handler_call }.to change { Authentication.where(provider: 'identity').count }
        end

        it 'agrees to terms of use and privacy policy when contracts_required' do
          expect {
            described_class.call(params: params, contracts_required: true)
          }.to change {
            FinePrint::Signature.count
          }.by(2)
        end

        it 'doesnt agree to terms of use and privacy policy when contracts NOT required' do
          expect {
            described_class.call(params: params, contracts_required: false)
          }.not_to change {
            FinePrint::Signature.count
          }
        end

        it 'creates an email address' do
          expect { handler_call }.to change { EmailAddress.count }
        end

        it 'outputs a user' do
          expect(handler_call.outputs.user).to be_present
        end
      end

      context 'when failure because a user with the given email address already exists' do
        before do
          create_newflow_user(email)
        end

        let(:email) do
          Faker::Internet.email
        end

        let(:params) do
          {
            signup: {
              email: email,
              password: Faker::Internet.password(min_length: 8),
              contract_1_id: 1,
              contract_2_id: 2
            }
          }
        end

        let(:result) do
          described_class.call(params: params)
        end

        example do
          expect(result.errors.first.message).to eq(I18n.t(:"login_signup_form.email_address_taken"))
          expect(result.errors).to have_offending_input(:email)
        end
      end

      context 'when user leaves the email blank' do
        let(:params) do
          {
            signup: {
              email: nil,
              password: Faker::Internet.password(min_length: 8),
              contract_1_id: 1,
              contract_2_id: 2
            }
          }
        end

        let(:result) do
          described_class.call(params: params)
        end

        example do
          expect(result.errors).to have_offending_input(:email)
        end
      end

      context 'when user leaves the password blank' do
        let(:params) do
          {
            signup: {
              email: Faker::Internet.email,
              password: nil,
              contract_1_id: 1,
              contract_2_id: 2
            }
          }
        end

        let(:result) do
          described_class.call(params: params)
        end

        example do
          expect(result.errors).to have_offending_input(:password)
        end
      end
    end
  end
end
