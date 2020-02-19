require 'rails_helper'

module Newflow
  RSpec.describe ConfirmOauthInfo, type: :handler do
    before do
      load 'db/seeds.rb'
      FactoryBot.create(:user, state: 'unverified')

      disable_sfdc_client
      allow(Settings::Salesforce).to receive(:push_leads_enabled) { true }
    end

    let(:params) do
      {
        info: {
          first_name: 'Bryan',
          last_name: 'Dimas',
          email: Faker::Internet.password(min_length: 8),
          newsletter: '1',
          terms_accepted: '1',
          contract_1_id: FinePrint::Contract.first.id,
          contract_2_id: FinePrint::Contract.last.id
        }
      }
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
      params[:info][:newsletter] = false
      described_class.call(params: params, contracts_required: true, user: User.last)
    end
  end
end
