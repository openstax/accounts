require 'rails_helper'

module Newflow
  RSpec.describe LoginSignupController, type: :controller do
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
          # GET login_form with `?r=URL` may store a safe url to return to after login
          get('login_form', params: { r: 'https://maliciousdomain.com' })

          post('login', params: params)
          expect(response).not_to redirect_to('https://maliciousdomain.com')
        end

        it 'creates a security log' do
          expect {
            post('login', params: params)
          }.to change {
            SecurityLog.where(event_type: :sign_in_successful, user: User.last).count
          }
        end
      end

      describe 'failure' do
        it 'creates a security log' do
          expect {
            post('login', params: { login_form: { email: 'user@openstax.org', password: 'wrongpassword' } })
          }.to change {
            SecurityLog.where(event_type: :login_not_found, event_data: { tried: 'user@openstax.org' }).count
          }
        end

        it 'saves the email to the session' do
          post('login', params: { login_form: { email: 'noone@openstax.org', password: 'wrongpassword' } })
          expect(session[:login_failed_email]).to  eq('noone@openstax.org')
        end
      end
    end

    describe 'GET #signup_form' do
      it 'renders (student!) signup_form' do
        get(:signup_form)
        expect(response).to  render_template(:signup_form)
      end
    end

    describe 'GET #welcome' do
      it 'renders welcome form/page' do
        get(:welcome)
        expect(response).to render_template(:welcome)
      end
    end

    describe 'POST #signup' do
      before do
        load('db/seeds.rb') # create the FinePrint contracts
      end

      it 'calls Handlers::StudentSignup' do
        expect_any_instance_of(StudentSignup).to receive(:call).once.and_call_original
        post(:signup)
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
              contract_2_id: FinePrint::Contract.second.id
            }
          }
        end

        it 'saves unverified user in the session' do
          expect_any_instance_of(described_class).to receive(:save_unverified_user).and_call_original
          post(:signup, params: params)
        end

        it 'creates a security log' do
          expect {
            post(:signup, params: params)
          }.to change {
            SecurityLog.where(event_type: :sign_up_successful, user: User.last)
          }
        end

        it 'redirects to confirmation_form_path' do
          post(:signup, params: params)
          expect(response).to  redirect_to(confirmation_form_path)
        end
      end

      context 'failure' do
        let(:params) do
          {
            signup: {
              first_name: 'Bryan',
              last_name: 'Dimas',
              email: '', # cause it to fail
              password: 'password',
              newsletter: false,
              terms_accepted: true,
              contract_1_id: FinePrint::Contract.first.id,
              contract_2_id: FinePrint::Contract.second.id
            }
          }
        end

        it 'renders signup form with errors' do
          post(:signup, params: params)
          expect(response).to render_template(:signup_form)
          expect(assigns(:"handler_result").errors).to  be_present
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
          post(:change_signup_email, params: params)
          expect(response).to render_template(:change_your_email)
        end
      end
    end

    describe 'confirmation_form_updated_email' do
      it ''
    end

    describe 'verify_email_by_pin' do
      it ''
    end

    describe 'verify_email_by_code' do
      it ''
    end

    describe 'signup_done' do

    end

    describe 'profile_newflow' do
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

    describe 'change_password_form' do
      it ''
    end

    describe 'set_new_password' do
      it ''
    end

    describe 'logout' do
      it ''
    end

    describe 'oauth_callback' do
      it ''
    end

    describe 'confirm_oauth_info' do
      it ''
    end

    describe 'send_password_setup_instructions' do
      it ''
    end

    describe 'setup_password' do
      it ''
    end

    describe 'GET #reset_password_form' do
      it 'has a 200 status code' do
        get('reset_password_form')
        expect(response.status).to eq(200)
      end

      it 'assigns the email value from what is stored in the session' do
        session[:login_failed_email] = 'someone@openstax.org'
        get('reset_password_form')
        expect(assigns(:email)).to eq('someone@openstax.org')
      end
    end

    describe 'POST #reset_password' do
      context 'success' do
          before do
            expect_any_instance_of(ResetPasswordForm).to receive(:call).once.and_call_original
          end

          let(:params) do
            { reset_password_form: { email: 'user@openstax.org' } }
          end

          it 'has a 200 status code' do
            post('reset_password', params: params)
            expect(response.status).to eq(200)
          end

          it 'assigns the email value from the handler\'s outputs' do
            post('reset_password', params: params)
            expect(assigns(:email)).to eq('user@openstax.org')
          end

          it 'calls sign_out!' do
            expect_any_instance_of(described_class).to receive(:sign_out!).once
            post('reset_password', params: params)
          end

          it 'renders reset_password_email_sent' do
            post('reset_password', params: params)
            expect(response).to render_template(:reset_password_email_sent)
          end

          it 'creates a Security Log' do
            user = create_newflow_user('user@openstax.org')

            expect {
              post('reset_password', params: params)
            }.to change {
              SecurityLog.where(event_type: :help_requested, user: user).count
            }
          end
      end

      context 'failure' do
          let(:params) do
            { reset_password_form: { email: '' } }
          end

          it 'creates a Security Log' do
            expect {
              post('reset_password', params: params)
            }.to change {
              SecurityLog.where(event_type: :help_request_failed).count
            }
          end

          it 'renders reset_password_form' do
            post('reset_password', params: params)
            expect(response).to render_template(:reset_password_form)
          end
      end
    end

  end
end
