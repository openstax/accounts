require 'rails_helper'
require 'byebug'

describe TermsController, type: :controller do
  let(:contract) { FactoryBot.create :fine_print_contract, :published }
  let!(:user_1)  { create_user 'user1' }
  let!(:user_2)  { create_user 'user2' }

  let(:trusted_return_url)   { 'https://openstax.org/example' }
  let(:untrusted_return_url) { 'https://www.example.com' }

  let(:token)    { FactoryBot.create(:doorkeeper_access_token, resource_owner_id: user_2.id).token }

  before         { controller.sign_in! user_1 }

  context 'pose_by_name' do
    context 'no params' do
      it 'renders pose form' do
        get :pose_by_name, params: { name: contract.name }
        expect(response).to render_template(:pose)
      end
    end

    context 'redirect and token params' do
      it 'passes params to form url' do
        get :pose_by_name, params: { name: contract.name, r: trusted_return_url, token: token }
        expect(response).to render_template(:pose)
      end
    end

    context 'invalid token' do
      it 'fails with 404 Not Found' do
        get :pose_by_name, params: { name: contract.name, token: SecureRandom.hex }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context 'agree' do
    context 'agreed' do
      context 'no token or return url' do
        it 'records the signature and redirects back' do
          expect do
            post :agree, params: { agreement: { contract_id: contract.id, i_agree: true } }
          end.to change { FinePrint::Signature.count }.by(1)
          signature = FinePrint::Signature.order(:created_at).last
          expect(signature.user).to eq user_1
          expect(response).to redirect_to('/')
        end
      end

      context 'token and trusted return url' do
        it 'records the signature for the token user and redirects back to the trusted url' do
          expect do
            post :agree, params: {
              agreement: { contract_id: contract.id, i_agree: true },
              r: trusted_return_url,
              token: token
            }
          end.to change { FinePrint::Signature.count }.by(1)
          signature = FinePrint::Signature.order(:created_at).last
          expect(signature.user).to eq user_2
          expect(response).to redirect_to(trusted_return_url)
        end
      end

      context 'invalid token' do
        it 'fails with 404 Not Found' do
          expect do
            post :agree, params: {
              agreement: { contract_id: contract.id, i_agree: true },
              token: SecureRandom.hex
            }
          end.not_to change { FinePrint::Signature.count }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'untrusted return url' do
        it 'ignores the untrusted url' do
          expect do
            post :agree, params: {
              agreement: { contract_id: contract.id, i_agree: true },
              r: untrusted_return_url
            }
          end.to change { FinePrint::Signature.count }.by(1)
          signature = FinePrint::Signature.order(:created_at).last
          expect(signature.user).to eq user_1
          expect(response).to redirect_to('/')
        end
      end
    end

    context 'did not agree' do
      it 'does not record a signature' do
        expect do
          post :agree, params: { agreement: { contract_id: contract.id } }
        end.not_to change { FinePrint::Signature.count }
        expect(response).to redirect_to('/')
      end
    end

  end
end
