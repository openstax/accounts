require 'rails_helper'

module Newflow
  RSpec.describe ConfirmOauthInfo, type: :handler do
    before do
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
          contract_1_id: '1',
          contract_2_id: '2'
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

    xit 'agrees to terms of use and privacy policy when contracts_required' do # TODO
      # TODO: ideally would do this but it fails with an error:
      # expect_any_instance_of(AgreeToTerms).to receive(:call).twice.and_call_original

      expect {
        described_class.call(params: params, contracts_required: true)
      }.to change {
        FinePrint::Signature.count
      }.by(2)
    end

    xit 'signs up user for the newsletter when checked' do # TODO
      expect_any_instance_of(PushSalesforceLead).to receive(:exec).with(hash_including({ newsletter: true }))
      result
    end

    xit 'does NOT sign up user for the newsletter when NOT checked' do # TODO
      expect_any_instance_of(PushSalesforceLead).to receive(:exec).with(hash_including({ newsletter: false }))
      params[:signup][:newsletter] = false
      result
    end
  end
end
