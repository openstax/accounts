require 'rails_helper'

RSpec.describe ConfirmOauthInfo, type: :handler do
  before do
    disable_sfdc_client
  end

  let(:params) do
    {
      signup: {
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        email: Faker::Internet.free_email,
        newsletter: true,
        terms_accepted: true,
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

    it 'signs up user for the newsletter when checked' do
      described_class.call(params: params, contracts_required: true, user: User.last)
      expect(User.last.receive_newsletter?).to be_truthy
    end

    it 'does NOT sign up user for the newsletter when NOT checked' do
      params[:signup][:newsletter] = false
      described_class.call(params: params, contracts_required: true, user: User.last)
      expect(User.last.receive_newsletter?).to be_falsey
    end
  end

  context 'when user has NO email address' do
    before do
      FactoryBot.create(:user, state: 'unverified')
    end

    xit 'creates an email address for the user' do
      expect {
        described_class.call(params: params, user: User.last)
      }.to(change(EmailAddress, :count))
    end

    it 'signs up user for the newsletter when checked' do
      described_class.call(params: params, contracts_required: true, user: User.last)
      expect(User.last.receive_newsletter?).to be_truthy
    end

    context 'when newsletter is not checked' do
      before do
        params[:signup][:newsletter] = false
      end

      it 'does not sign up user for the newsletter' do
        described_class.call(params: params, contracts_required: true, user: User.last)
        expect(User.last.receive_newsletter?).to be_falsey
      end
    end
  end
end
