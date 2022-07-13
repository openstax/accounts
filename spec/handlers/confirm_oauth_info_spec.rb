require 'rails_helper'

RSpec.describe ConfirmOauthInfo, type: :handler do
  before do
    disable_sfdc_client
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
      expect_any_instance_of(CreateSalesforceLead).to receive(:exec)
      described_class.call(params: params, user: User.last)
    end

    it 'signs up user for the newsletter when checked' do
      expect_any_instance_of(CreateSalesforceLead).to receive(:exec)
      described_class.call(params: params, contracts_required: true, user: User.last)
    end

    it 'does NOT sign up user for the newsletter when NOT checked' do
      expect_any_instance_of(CreateSalesforceLead).not_to receive(:exec)
      params[:signup][:newsletter] = false
      described_class.call(params: params, contracts_required: true, user: User.last)
    end
  end
end
