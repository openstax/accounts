require 'rails_helper'

RSpec.describe SocialAuthController, type: :controller do
  describe 'GET #oauth_callback' do
    let(:info) { { email: 'user@openstax.org', name: Faker::Name.name } }

    before do
      allow_any_instance_of(OauthCallback).to receive(:oauth_response)  do
        MockOmniauthRequest.new(params[:provider], params[:uid], info).env['omniauth.auth']
      end
    end

    it 'calls OauthCallback handler' do
      expect_any_instance_of(OauthCallback).to receive(:call).once.and_call_original
      get(:oauth_callback, params: { provider: 'facebook' })
    end

    context 'social signup as a student' do
      let(:params) { { provider: 'facebook', uid: Faker::Internet.uuid, email: Faker::Internet.safe_email } }

      it 'signs the user in and renders confirm_social_info_form' do
        expect_any_instance_of(described_class).to receive(:sign_in!).and_call_original
        post(:oauth_callback, params: params)
        expect(response).to redirect_to(confirm_oauth_info_path)
      end
    end

    context 'failure' do
      context 'with mismatched_authentication' do
        before do
          allow_any_instance_of(OauthCallback).to receive(:mismatched_authentication?).and_return(true)
        end

        let(:params) { { provider: 'facebook', uid: Faker::Internet.uuid } }

        it 'redirects to login' do
          get(:oauth_callback, params: params)
          expect(response).to redirect_to(login_path)
        end
      end

      context 'when no email address is returned' do
        let(:info) { { email: nil, name: Faker::Name.name } }
        let(:params) { { provider: 'facebook', uid: Faker::Internet.uuid } }

        before do
          allow_any_instance_of(OauthCallback).to receive(:oauth_response)  do
            MockOmniauthRequest.new(params[:provider], params[:uid], info).env['omniauth.auth']
          end
        end

        it 'fails gracefully - not returning a 500' do
          get(:oauth_callback, params: params)
          expect(response).not_to have_http_status(:server_error)
        end
      end
    end
  end
end
