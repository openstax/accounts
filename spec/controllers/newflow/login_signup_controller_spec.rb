require 'rails_helper'

module Newflow
  RSpec.describe LoginSignupController, type: :controller do

    describe 'GET #welcome' do
      it 'renders welcome form/page' do
        get(:welcome)
        expect(response).to render_template(:welcome)
      end
    end

    describe 'GET #login_form' do
      example 'success' do
        get(:login_form)
        expect(response).to have_http_status(:success)
      end
    end

    describe 'POST #login' do
      describe 'success' do
        before do
          create_newflow_user('user@openstax.org', 'password')
          expect_any_instance_of(AuthenticateUser).to receive(:call).once.and_call_original
        end

        let(:params) do
          { login_form: { email: 'user@openstax.org', password: 'password' } }
        end

        it 'logs in the user' do
          expect_any_instance_of(described_class).to receive(:sign_in!).once.and_call_original
          post('login', params: params)
          expect(assigns(:current_user)).to eq(User.last)
        end

        it 'redirects on success' do
          post('login', params: params)
          expect(response).to have_http_status(:redirect)
        end

        it 'redirects back to `r`eturn parameter' do
          path = Faker::Internet.slug

          # GET login_form with `?r=URL` stores the url to return to after login
          get('login_form', params: { r: "https://openstax.org/#{path}" })

          post('login', params: params)
          expect(response).to redirect_to("https://openstax.org/#{path}")
        end

        it 'checks `r`eturn parameter is whitelisted' do
          expect(Host).to receive(:trusted?).once.and_call_original
          # GET login_form with `?r=URL` may store a SAFE url to return to after login
          get('login_form', params: { r: 'https://maliciousdomain.com' })

          post('login', params: params)
          expect(response).not_to redirect_to('https://maliciousdomain.com')
        end

        it 'creates a security log' do
          expect {
            post('login', params: params)
          }.to change {
            SecurityLog.where(event_type: :sign_in_successful).count
          }
        end
      end

      describe 'failure' do
        describe 'when cannot_find_user' do
          it 'creates a security log' do
            expect {
              post('login', params: { login_form: { email: 'noone@openstax.org', password: 'password' } })
            }.to change {
              SecurityLog.sign_in_failed.where(event_data: { reason: :cannot_find_user, user: nil}).count
            }
          end
        end

        describe 'when multiple_users' do
          before do
            user1 = create_user 'user1'
            email1 = create_email_address_for(user1, email_address)
            user2 = create_user 'user2'
            email2 = create_email_address_for(user2, 'user-2@example.com')
            ContactInfo.where(id: email2.id).update_all(value: email1.value)
          end

          let(:email_address) do
            'user@example.com'
          end

          it 'creates a security log' do
            expect {
              post('login', params: { login_form: { email: email_address, password: 'password' } })
            }.to change {
              SecurityLog.where(event_type: :sign_in_failed).count
            }
          end
        end

        describe 'when too_many_login_attempts' do
          before do
            stub_const 'RateLimiting::MAX_LOGIN_ATTEMPTS_PER_USER', max_attempts_per_user
          end

          let(:email) { FactoryBot.create(:email_address, user: user, verified: true) }
          let(:user) { FactoryBot.create(:user) }
          let(:max_attempts_per_user) { 0 }

          it 'creates a security log' do
            expect {
              post('login', params: { login_form: { email: email.value, password: 'wrongpassword' } })
            }.to change {
              SecurityLog.where(
                event_type: :sign_in_failed,
                event_data: {
                  reason: :too_many_login_attempts,
                  user: user
                }
              ).count
            }
          end
        end

        it 'saves the email to the session' do
          post('login', params: { login_form: { email: 'noone@openstax.org', password: 'wrongZpassword' } })
          expect(session[:login_failed_email]).to  eq('noone@openstax.org')
        end
      end
    end

    describe 'GET #signup_form' do
      it 'renders (student!) signup_form' do
        get(:student_signup_form)
        expect(response).to  render_template(:student_signup_form)
      end
    end

    describe 'POST #educator_signup' do
      before do
        load('db/seeds.rb') # create the FinePrint contracts
      end

      it 'calls Handlers::EducatorSignup' do
        expect_any_instance_of(EducatorSignup).to receive(:call).once.and_call_original
        post(:educator_signup)
      end

      context 'success' do
        let(:params) do
          {
            signup: {
              first_name: 'Bryan',
              last_name: 'Dimas',
              email: 'user2@openstax.org',
              password: 'password',
              phone_number: Faker::PhoneNumber.phone_number_with_country_code,
              newsletter: false,
              terms_accepted: true,
              contract_1_id: FinePrint::Contract.first.id,
              contract_2_id: FinePrint::Contract.second.id,
              role: :instructor
            }
          }
        end

        it 'saves unverified user in the session' do
          expect_any_instance_of(described_class).to receive(:save_unverified_user).and_call_original
          post(:educator_signup, params: params)
        end

        it 'creates a security log' do
          expect {
            post(:educator_signup, params: params)
          }.to change {
            SecurityLog.where(event_type: :sign_up_successful, user: User.last)
          }
        end

        it 'redirects to confirmation_form_path' do
          post(:educator_signup, params: params)
          expect(response).to  redirect_to(confirmation_form_path)
        end
      end

      context 'failure' do
        let(:params) do
          {
            signup: {
              first_name: 'Bryan',
              last_name: 'Dimas',
              email: '1', # cause it to fail
              password: 'password',
              phone_number: Faker::PhoneNumber.phone_number_with_country_code,
              newsletter: false,
              terms_accepted: true,
              contract_1_id: FinePrint::Contract.first.id,
              contract_2_id: FinePrint::Contract.second.id,
              role: :instructor
            }
          }
        end

        it 'renders instructor signup form with errors' do
          post(:educator_signup, params: params)

          expect(response).to render_template(:educator_signup_form)
          expect(assigns(:"handler_result").errors).to  be_present
        end

        it 'creates a security log' do
          EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new(expecting: false)

          expect {
            post(:educator_signup, params: params)
          }.to change {
            SecurityLog.educator_sign_up_failed.count
          }
        end
      end
    end

    describe 'POST #student_signup' do
      before do
        load('db/seeds.rb') # create the FinePrint contracts
      end

      it 'calls Handlers::StudentSignup' do
        expect_any_instance_of(StudentSignup).to receive(:call).once.and_call_original
        post(:student_signup)
      end

      context 'success' do
        let(:params) do
          {
            signup: {
              first_name: 'Bryan',
              last_name: 'Dimas',
              email: 'user2@openstax.org',
              password: 'password',
              newsletter: false,
              terms_accepted: true,
              contract_1_id: FinePrint::Contract.first.id,
              contract_2_id: FinePrint::Contract.second.id,
              role: :student
            }
          }
        end

        it 'saves unverified user in the session' do
          expect_any_instance_of(described_class).to receive(:save_unverified_user).and_call_original
          post(:student_signup, params: params)
        end

        it 'creates a security log' do
          expect {
            post(:student_signup, params: params)
          }.to change {
            SecurityLog.where(event_type: :sign_up_successful, user: User.last)
          }
        end

        it 'redirects to confirmation_form_path' do
          post(:student_signup, params: params)
          expect(response).to  redirect_to(confirmation_form_path)
        end
      end

      context 'failure' do
        let(:params) do
          {
            signup: {
              first_name: 'Bryan',
              last_name: 'Dimas',
              email: '1', # cause it to fail
              password: 'password',
              newsletter: false,
              terms_accepted: true,
              contract_1_id: FinePrint::Contract.first.id,
              contract_2_id: FinePrint::Contract.second.id,
              role: :student
            }
          }
        end

        it 'renders student signup form with errors' do
          post(:student_signup, params: params)

          expect(response).to render_template(:student_signup_form)
          expect(assigns(:"handler_result").errors).to  be_present
        end

        it 'creates a security log' do
          EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new(expecting: false)

          expect {
            post(:student_signup, params: params)
          }.to change {
            SecurityLog.student_sign_up_failed.count
          }
        end
      end
    end

    describe 'GET #confirmation_form' do
      it 'renders confirmation_form unless missing unverified_user' do
        get(:confirmation_form)
        expect(response).to redirect_to newflow_signup_path

        user = create_newflow_user('user@openstax.org')
        user.update_attribute('state', 'unverified')
        session[:unverified_user_id] = user.id

        get(:confirmation_form)
        expect(response).to render_template(:confirmation_form)
      end
    end

    describe 'POST #change_signup_email' do
      before do
        create_newflow_user('original@openstax.org')
      end

      context 'success' do
        let(:params) {
          {
            change_signup_email: {
              email: 'newemail@openstax.org'
            }
          }
        }

        it 'redirects to confirmation_form_updated_email_path' do
          user = User.last
          user.update_attribute('state', 'unverified')
          session[:unverified_user_id] = user.id
          post(:change_signup_email, params: params)
          expect(response).to redirect_to confirmation_form_updated_email_path
        end
      end

      context 'failure' do
        params = {
          change_signup_email: {
            email: '' # cause a failure
          }
        }

        it 'renders change_your_email' do
          user = User.last
          user.update_attribute('state', 'unverified')
          session[:unverified_user_id] = user.id

          post(:change_signup_email, params: params)
          expect(response).to render_template(:change_your_email)
        end
      end
    end

    describe 'confirmation_form_updated_email' do
      it 'renders OK' do
        user = create_newflow_user('user@openstax.org')
        allow_any_instance_of(LoginSignupController).to receive(:unverified_user) { user }
        get('confirmation_form_updated_email')
        expect(response.status).to eq(200)
        expect(response).to render_template(:confirmation_form_updated_email)
      end

      it 'redirects when there is no unverified_user present' do
        get('confirmation_form_updated_email')
        expect(response.status).to eq(302)
      end
    end

    describe 'verify_email_by_pin' do
      it ''
    end

    describe 'verify_email_by_code' do
      it ''
    end

    describe 'GET #signup_done' do
      it 'renders' do
        get(:signup_done)
        expect(response).to render_template(:signup_done)
      end
    end

    describe 'GET #profile' do
      context 'when logged in' do
        before do
          mock_current_user(create_newflow_user('user@openstax.org'))
        end

          it 'renders 200 OK status' do
          get(:profile_newflow)
          expect(response.status).to eq(200)
        end

        it 'renders profile_newflow' do
          get(:profile_newflow)
          expect(response).to render_template(:profile_newflow)
        end
      end

      context 'while not logged in' do
        it 'redirects to login form' do
          get(:profile_newflow)
          expect(response).to redirect_to newflow_login_path
        end
      end
    end

    describe 'GET #logout' do
      it 'redirects to caller-specified URL if in whitelist' do
        get(:logout, params: { r: "https://something.openstax.org/howdy?blah=true" })
        expect(response).to redirect_to("https://something.openstax.org/howdy?blah=true")
      end

      it 'does not redirect to a caller-specified URL if not in whitelist' do
        get(:logout, params: { r: "http://www.google.com" })
        expect(response).to redirect_to("/")
      end
    end

    describe 'GET #oauth_callback' do
      let(:info) do
        { email: 'user@openstax.org', name: Faker::Name.name }
      end

      before do
        allow_any_instance_of(OauthCallback).to receive(:oauth_response)  do
          # TODO: refactor this?
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
          expect_any_instance_of(LoginSignupController).to receive(:save_unverified_user)
          get(:oauth_callback, params: params)
        end

        it 'renders confirm_social_info_form' do
          get(:oauth_callback, params: params)
          expect(response).to render_template(:confirm_social_info_form)
        end
      end

      context 'failure' do
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
    end

    describe 'GET #confirm_oauth_info' do
      it ''
    end

    describe 'GET #create_password_form' do
      context 'without a token' do
        it 'renders create_password_form but with status 400' do
          get(:create_password_form)
          expect(response).to render_template(:create_password_form)
          expect(response.status).to eq(400)
        end
      end

      context 'with an invalid token' do
        it 'renders create_password_form but with status 400' do
          get(:create_password_form, params: { token: '123' })
          expect(response).to render_template(:create_password_form)
          expect(response.status).to eq(400)
        end
      end

      context 'with a valid token' do
        before do
          user = create_newflow_user('user@openstax.org')
          @token = generate_login_token_for_user(user)
        end

        it 'renders create_password_form with status 200' do
          get(:create_password_form, params: { token: @token })
          expect(response).to render_template(:create_password_form)
          expect(response.status).to eq(200)
        end
      end
    end

    describe 'POST #create_password' do
      it 'creates a password for logged in user'
    end

    describe 'GET #forgot_password_form' do
      it 'has a 200 status code' do
        get('forgot_password_form')
        expect(response.status).to eq(200)
      end

      it 'assigns the email value from what is stored in the session' do
        session[:login_failed_email] = 'someone@openstax.org'
        get('forgot_password_form')
        expect(assigns(:email)).to eq('someone@openstax.org')
      end
    end

    describe 'POST #send_reset_password_email' do
      context 'success' do
          before do
            create_newflow_user('user@openstax.org')
            expect_any_instance_of(SendResetPasswordEmail).to receive(:call).once.and_call_original
          end

          let(:params) do
            { forgot_password_form: { email: 'user@openstax.org' } }
          end

          it 'assigns the email value from the handler\'s outputs' do
            post('send_reset_password_email', params: params)
            expect(assigns(:email)).to eq('user@openstax.org')
          end

          it 'calls sign_out!' do
            expect_any_instance_of(described_class).to receive(:sign_out!).once
            post('send_reset_password_email', params: params)
          end

          it 'redirects to reset_password_email_sent' do
            post('send_reset_password_email', params: params)
            expect(response).to render_template(:reset_password_email_sent)
          end

          it 'creates a Security Log' do
            mock_current_user(User.last)
            expect {
              post('send_reset_password_email', params: params)
            }.to change {
              SecurityLog.where(event_type: :help_requested, user: User.last).count
            }
          end
      end

      context 'failure' do
          let(:params) do
            { forgot_password_form: { email: '' } }
          end

          it 'creates a Security Log' do
            expect {
              post('send_reset_password_email', params: params)
            }.to change {
              SecurityLog.where(event_type: :reset_password_failed).count
            }
          end

          it 'renders forgot password form' do
            post('send_reset_password_email', params: params)
            expect(response).to render_template(:forgot_password_form)
          end
      end
    end

    describe 'GET #change_password_form' do
      context 'success - when valid token' do
        let(:params) do
          user.refresh_login_token
          user.save

          { token:  user.login_token }
        end

        let(:user) do
          create_newflow_user('user@openstax.org')
        end

        it 'logs in the user found by token or whateva' do
          some_other_user = FactoryBot.create(:user)
          get('change_password_form', params: params)
          expect(controller.current_user.id).to eq(user.id)
          expect(controller.current_user.id).not_to eq(some_other_user.id)
        end

        it 'has a 200 status code' do
          get('change_password_form', params: params)
          expect(response.status).to eq(200)
        end

        xit 'creates a security log' do
          expect {
            get('change_password_form', params: params)
          }.to change {
            SecurityLog.where(event_type: :help_requested).count
          }
        end
      end

      context 'failure - when invalid token' do
        before do
          user = FactoryBot.create(:user)
        end

        let(:params) do
          { token: SecureRandom.hex(16) } # token is invalid because it doesn't match up with the user's
        end

        it 'responds with 400 error' do
          get('change_password_form', params: params)
          expect(response.code).to eq('400')
        end

        it 'creates a security log' do
          expect {
            get('change_password_form', params: params)
          }.to change {
            SecurityLog.where(event_type: :help_request_failed).count
          }
        end
      end
    end

    describe 'POST #change_password' do
      before do
        # bypass re-authentication
        allow_any_instance_of(RequireRecentSignin).to receive(:user_signin_is_too_old?).and_return(false)
        mock_current_user(user)
      end

      let(:user) do
        create_newflow_user('user@openstax.org', 'password')
      end

      context 'success' do
        let(:new_password) do
          Faker::Internet.password(min_length: 8)
        end

        let(:params) do
          {
            change_password_form: {
              password: new_password
            }
          }
        end

        it 'sets the new password for the user' do
          expect(User.last.identity.authenticate(new_password)).to be_falsey
          post(:change_password, params: params)
          expect(response.status).to eq(302)
          expect(User.last.identity.authenticate(new_password)).to be_truthy
        end

        it 'creates a security log' do
          expect {
            post('change_password', params: params)
          }.to change {
            SecurityLog.where(event_type: :password_reset).count
          }
        end
      end

      context 'failure' do
        before do
          # bypass re-authentication
          allow_any_instance_of(RequireRecentSignin).to receive(:user_signin_is_too_old?).and_return(false)
        end

        let(:params) do
          {
            change_password_form: {
              password: ''
            }
          }
        end

        it 'creates a security log' do
          expect {
            post('change_password', params: params)
          }.to change {
            SecurityLog.where(event_type: :password_reset_failed).count
          }
        end
      end
    end
  end
end
