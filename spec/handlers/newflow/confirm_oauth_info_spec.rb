require 'rails_helper'

module Newflow
  RSpec.describe ConfirmOauthInfo, type: :handler do
    before do
      disable_sfdc_client
      allow(Settings::Salesforce).to receive(:push_leads_enabled) { true }
    end

    let(:params) do
      {
        signup: {
          first_name: 'Bryan',
          last_name: 'Dimas',
          email: Faker::Internet.free_email,
          newsletter: '1',
          terms_accepted: '1',
          contract_1_id: FinePrint::Contract.first.id,
          contract_2_id: FinePrint::Contract.last.id
        }
      }
    end

    context 'when user has an email address' do
      before do
        user = FactoryBot.create(:user, state: 'unverified')
        FactoryBot.create(:email_address, value: params[:signup][:email], user: user)
      end

      it 'adds the user as a "lead" to salesforce' do
        expect_any_instance_of(PushSalesforceLead).to receive(:exec)
        described_class.call(params: params, user: User.last)
      end

      it 'changes the user state to "activated"' do
        expect(User.last.state).to_not eq('activated')
        described_class.call(params: params, user: User.last)
        expect(User.last.state).to eq('activated')
      end

      it 'agrees to terms of use and privacy policy when contracts_required' do
        # TODO: ideally would do this but it fails with an error:
        # expect_any_instance_of(AgreeToTerms).to receive(:call).twice.and_call_original

        expect {
          described_class.call(params: params, contracts_required: true, user: User.last)
        }.to change {
          FinePrint::Signature.count
        }.by(2)
      end

      it 'signs up user for the newsletter when checked' do
        expect_any_instance_of(PushSalesforceLead).to receive(:exec).with(hash_including({ newsletter: true }))
        described_class.call(params: params, contracts_required: true, user: User.last)
      end

      it 'does NOT sign up user for the newsletter when NOT checked' do
        expect_any_instance_of(PushSalesforceLead).to receive(:exec).with(hash_including({ newsletter: false }))
        params[:signup][:newsletter] = false
        described_class.call(params: params, contracts_required: true, user: User.last)
      end
    end

    context 'when user has NO email address' do
      before do
        FactoryBot.create(:user, state: 'unverified')
      end

      it 'creates an email address for the user' do
        expect {
          described_class.call(params: params, user: User.last)
        }.to(
          change(EmailAddress, :count)
        )
      end

      it 'adds the user as a "lead" to salesforce' do
        expect_any_instance_of(PushSalesforceLead).to receive(:exec)
        described_class.call(params: params, user: User.last)
      end

      it 'changes the user state to "activated"' do
        expect(User.last.state).to_not eq('activated')
        described_class.call(params: params, user: User.last)
        expect(User.last.state).to eq('activated')
      end

      it 'agrees to terms of use and privacy policy when contracts_required' do
        # TODO: ideally would do this but it fails with an error:
        # expect_any_instance_of(AgreeToTerms).to receive(:call).twice.and_call_original

        expect {
          described_class.call(params: params, contracts_required: true, user: User.last)
        }.to change {
          FinePrint::Signature.count
        }.by(2)
      end

      it 'signs up user for the newsletter when checked' do
        expect_any_instance_of(PushSalesforceLead).to receive(:exec).with(hash_including({ newsletter: true }))
        described_class.call(params: params, contracts_required: true, user: User.last)
      end

      it 'does NOT sign up user for the newsletter when NOT checked' do
        expect_any_instance_of(PushSalesforceLead).to receive(:exec).with(hash_including({ newsletter: false }))
        params[:signup][:newsletter] = false
        described_class.call(params: params, contracts_required: true, user: User.last)
      end
    end
  end
end
