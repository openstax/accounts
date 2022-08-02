require 'rails_helper'

RSpec.describe SocialAuthController, type: :controller do
  describe 'GET #oauth_callback' do
    let(:info) do
      { email: 'user@openstax.org', name: Faker::Name.name }
    end

    before do
      allow_any_instance_of(OauthCallback).to receive(:oauth_response)  do
        MockOmniauthRequest.new(params[:provider], params[:uid], info).env['omniauth.auth']
      end
    end

    it 'calls OauthCallback handler' do
      expect_any_instance_of(OauthCallback).to receive(:call).once.and_call_original
      get(:oauth_callback, params: { provider: 'facebook' })
    end

    context 'social login (login means user.state == activated) - success' do
      let(:user) do
        create_user('user@openstax.org')
      end

      let(:params) do
        { provider: 'facebook', uid: Faker::Internet.uuid }
      end

      before do
        FactoryBot.create :authentication, user: user, provider: params[:provider], uid: params[:uid]
      end

      it 'responds with 302 redirect' do
        get(:oauth_callback, params: params)
        assert_response :redirect
      end

      it 'signs in the user' do
        expect_any_instance_of(described_class).to receive(:sign_in!).and_call_original
        get(:oauth_callback, params: params)
      end
    end

    context 'social signup (signup means user.state != activated) - success' do
      let(:params) do
        { provider: 'facebook', uid: Faker::Internet.uuid }
      end

      it 'saves unverified user' do
        expect_any_instance_of(described_class).to receive(:save_unverified_user)
        get(:oauth_callback, params: params)
      end

      it 'renders confirm_social_info_form' do
        get(:oauth_callback, params: params)
        expect(response).to render_template(:confirm_social_info_form)
      end
    end

    context 'failure' do
      context 'with mismatched_authentication' do
        before do
          allow_any_instance_of(OauthCallback).to receive(:mismatched_authentication?).and_return(true)
        end

        let(:params) do
          { provider: 'facebook', uid: 'nonexistent' }
        end

        it 'redirects to login' do
          get(:oauth_callback, params: params)
          expect(response).to redirect_to(login_path)
        end

        it 'saves login failed email' do
          expect_any_instance_of(described_class).to receive(:save_login_failed_email).and_call_original
          get(:oauth_callback, params: params)
          expect(session[:login_failed_email]).to eq(info[:email])
        end
      end

      context 'when no email address is returned' do
        let(:info) do
          { email: nil, name: Faker::Name.name }
        end

        let(:params) do
          { provider: 'facebook', uid: Faker::Internet.uuid }
        end

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

  describe 'GET #confirm_oauth_info' do
    it ''
  end
end
