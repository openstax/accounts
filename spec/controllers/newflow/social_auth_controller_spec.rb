require 'rails_helper'

module Newflow
  describe SocialAuthController, type: :controller do
    describe 'GET #oauth_callback' do
      let(:info) do
        { email: 'user@openstax.org', name: Faker::Name.name }
      end

      before do
        # Set omniauth.auth in the request env so the controller guard clause passes,
        # and stub the handler's oauth_response to use the same mock data.
        request.env['omniauth.auth'] = { provider: 'facebooknewflow', uid: '123', info: info }
        allow_any_instance_of(OauthCallback).to receive(:oauth_response) do
          MockOmniauthRequest.new(params[:provider], params[:uid], info).env['omniauth.auth']
        end
      end

      it 'calls OauthCallback handler' do
        expect_any_instance_of(OauthCallback).to receive(:call).once.and_call_original
        get(:oauth_callback, params: { provider: 'facebook' })
      end

      context 'social login (login means user.state == activated) - success' do
        let(:user) do
          create_newflow_user('user@openstax.org')
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

      context 'with a signed token in the state param' do
        let(:user)      { FactoryBot.create :user, state: User::EXTERNAL }
        let(:return_to) { 'http://localhost' }
        let(:state)     do
          Rails.application.message_verifier('social_auth').generate({
            user_id: user.id,
            return_to: return_to
          }.to_json)
        end

        let(:params) { { provider: 'facebook', uid: Faker::Internet.uuid, state: state } }

        it 'does not save unverified user' do
          expect_any_instance_of(described_class).not_to receive(:save_unverified_user)
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
            expect(response).to redirect_to(newflow_login_path)
          end

          it 'saves login failed email' do
            expect_any_instance_of(described_class).to receive(:save_login_failed_email).and_call_original
            get(:oauth_callback, params: params)
            expect(session[:login_failed_email]).to eq(info[:email])
          end
        end

        context 'when omniauth.auth is missing (no OmniAuth middleware)' do
          let(:params) do
            { provider: 'facebook' }
          end

          before do
            # Don't set omniauth.auth in the request env — simulates a direct hit
            # bypassing OmniAuth middleware (bots, expired sessions, etc.)
            allow_any_instance_of(OauthCallback).to receive(:oauth_response).and_return(nil)
            request.env['omniauth.auth'] = nil
          end

          it 'redirects to login without invoking the handler' do
            expect_any_instance_of(OauthCallback).not_to receive(:call)
            get(:oauth_callback, params: params)
            expect(response).to redirect_to(newflow_login_path)
          end

          it 'sets an alert flash message' do
            get(:oauth_callback, params: params)
            expect(flash[:alert]).to be_present
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

    describe 'POST #confirm_oauth_info' do
      before(:all) do
        DatabaseCleaner.start
        load('db/seeds.rb')
      end

      after(:all) { DatabaseCleaner.clean }

      context 'with valid params' do
        let(:valid_params) do
          {
            signup: {
              first_name: 'Test',
              last_name: 'User',
              email: 'test@example.com',
              contract_1_id: FinePrint::Contract.first.id,
              contract_2_id: FinePrint::Contract.second.id,
              terms_accepted: true
            }
          }
        end

        context 'with a signed token in the token param' do
          let(:user)      { FactoryBot.create :user, state: User::EXTERNAL }
          let(:return_to) { 'http://localhost' }
          let(:token)     do
            Rails.application.message_verifier('social_auth').generate({
              user_id: user.id,
              return_to: return_to
            }.to_json)
          end

          let(:params) { valid_params.merge(token: token) }

          it 'confirms the user in the token and redirects to the return_to url' do
            post :confirm_oauth_info, params: params
            expect(response).to redirect_to(return_to)
            expect(user.reload).to be_activated
          end
        end

        context 'without a signed token in the token param' do
          let(:params) { valid_params }

          context 'with a saved unverified_user' do
            let(:user)   { FactoryBot.create :user, state: User::UNVERIFIED }

            before { controller.save_unverified_user user.id }

            it 'confirms the saved unverified_user and redirects to the signup_done path' do
              post :confirm_oauth_info, params: params
              expect(response).to redirect_to :signup_done
              expect(user.reload).to be_activated
            end
          end

          context 'without a saved unverified_user' do
            it 'restarts signup' do
              post :confirm_oauth_info, params: params
              expect(response).to redirect_to :newflow_signup
            end
          end
        end
      end

      context 'with invalid params' do
        render_views

        let(:user)   { FactoryBot.create :user, state: User::UNVERIFIED }

        let(:params) do
          {
            signup: {
              first_name: 'Test',
              last_name: 'User',
              email: '',
              contract_1_id: FinePrint::Contract.first.id,
              contract_2_id: FinePrint::Contract.second.id,
              terms_accepted: true
            }
          }
        end

        before { controller.save_unverified_user user.id }

        it 're-renders the form with an error message' do
          post :confirm_oauth_info, params: params
          expect(response.body).to include("Email can't be blank")
        end
      end
    end
  end
end
