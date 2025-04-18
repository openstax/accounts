require 'rails_helper'

module Newflow
  describe ConfirmOauthInfo, type: :handler do
    before do
      disable_sfdc_client
    end

    let(:params) do
      {
        signup: {
          first_name: 'Bryan',
          last_name: 'Dimas',
          email: Faker::Internet.email,
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

      it 'works as expected' do
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
        }.to(change(EmailAddress, :count))
      end
    end
  end
end
