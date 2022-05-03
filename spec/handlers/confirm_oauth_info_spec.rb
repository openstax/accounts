require 'rails_helper'

RSpec.describe ConfirmOauthInfo, type: :handler do
  before do
    disable_sfdc_client
  end

  let(:email) { Faker::Internet.email }

  let(:params) do
    {
      signup: {
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        email: email,
        newsletter: false,
        terms_accepted: true,
        contract_1_id: FinePrint::Contract.first.id,
        contract_2_id: FinePrint::Contract.last.id
      }
    }
  end

  let(:user) { create_user email }

  context 'when user has an email address' do
    it 'successfully confirms the info' do
      described_class.call(params: params, user: user)
    end

    it 'creates an email address for the user' do
      expect {
        described_class.call(params: params, user: user)
      }.to(change(EmailAddress, :count))
    end

    it 'signs up user for the newsletter when checked' do
      params[:newsletter] = true
      described_class.call(params: params, contracts_required: true, user: user)
      expect(user.receive_newsletter).to be_truthy

    end

    it 'does not sign up user for the newsletter' do
      params[:signup][:newsletter] = false
      described_class.call(params: params, contracts_required: true, user: user)
      expect(user.receive_newsletter).to be_falsey
    end
  end
end
