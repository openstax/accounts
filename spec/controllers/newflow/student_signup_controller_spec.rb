require 'rails_helper'

module Newflow
  describe StudentSignupController, type: :controller do
    describe 'GET #student_signup_form' do
      it 'renders student signup_form' do
        get(:student_signup_form)
        expect(response).to  render_template(:student_signup_form)
      end
    end

    describe 'POST #student_signup' do
      before do
        load('db/seeds.rb') # create the FinePrint contracts
      end

      it 'calls Handlers::StudentSignup::SignupForm' do
        expect_any_instance_of(StudentSignup::SignupForm).to receive(:call).once.and_call_original
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
            SecurityLog.where(event_type: :student_signed_up, user: User.last).count
          }
        end

        it 'includes redirect URL in security log message when present' do
          redirect_url = "https://openstax.org/books/biology-2e"
          # GET student_signup_form with `?r=URL` stores the url
          get(:student_signup_form, params: { r: redirect_url })

          post(:student_signup, params: params)

          log = SecurityLog.where(event_type: :student_signed_up).last
          expect(log.event_data['redirect']).to eq(redirect_url)
        end

        it 'does not include redirect URL in security log message when absent' do
          post(:student_signup, params: params)

          log = SecurityLog.where(event_type: :student_signed_up).last
          expect(log.event_data['redirect']).to be_nil
        end

        it 'redirects to student_email_verification_form_path' do
          post(:student_signup, params: params)
          expect(response).to  redirect_to(student_email_verification_form_path)
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

      context 'when recaptcha is disabled' do
        let(:params) do
          {
            signup: {
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
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

        before do
          allow(Settings::Recaptcha).to receive(:disabled?) { true }
        end

        it 'bypasses recaptcha verification and allows signup' do
          expect_any_instance_of(described_class).not_to receive(:verify_recaptcha)
          post(:student_signup, params: params)
          expect(response).to redirect_to(student_email_verification_form_path)
        end
      end
    end

    describe 'POST #student_change_signup_email' do
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

        it 'redirects to student_email_verification_form_updated_email_path' do
          user = User.last
          user.update_attribute('state', 'unverified')
          session[:unverified_user_id] = user.id
          post(:student_change_signup_email, params: params)
          expect(response).to redirect_to(student_email_verification_form_updated_email_path)
        end
      end

      context 'failure' do
        params = {
          change_signup_email: {
            email: '' # cause a failure
          }
        }

        it 'renders student_change_signup_email_form' do
          user = User.last
          user.update_attribute('state', 'unverified')
          session[:unverified_user_id] = user.id

          post(:student_change_signup_email, params: params)
          expect(response).to render_template(:student_change_signup_email_form)
        end
      end

      context 'when recaptcha is disabled' do
        let(:params) {
          {
            change_signup_email: {
              email: 'newemail@openstax.org'
            }
          }
        }

        before do
          allow(Settings::Recaptcha).to receive(:disabled?) { true }
        end

        it 'bypasses recaptcha verification and allows email change' do
          user = User.last
          user.update_attribute('state', 'unverified')
          session[:unverified_user_id] = user.id
          expect_any_instance_of(described_class).not_to receive(:verify_recaptcha)
          post(:student_change_signup_email, params: params)
          expect(response).to redirect_to(student_email_verification_form_updated_email_path)
        end
      end
    end

    describe 'GET #student_email_verification_form' do
      it 'renders student_email_verification_form unless missing unverified_user' do
        get(:student_email_verification_form)
        expect(response).to redirect_to newflow_signup_path

        user = create_newflow_user('user@openstax.org')
        user.update_attribute('state', 'unverified')
        session[:unverified_user_id] = user.id

        get(:student_email_verification_form)
        expect(response).to render_template(:student_email_verification_form)
      end
    end

    describe 'GET #student_email_verification_form_updated_email' do
      it 'renders OK' do
        user = create_newflow_user('user@openstax.org')
        allow_any_instance_of(described_class).to receive(:unverified_user) { user }
        get('student_email_verification_form_updated_email')
        expect(response.status).to eq(200)
        expect(response).to render_template(:student_email_verification_form_updated_email)
      end

      it 'redirects when there is no unverified_user present' do
        get('student_email_verification_form_updated_email')
        expect(response.status).to eq(302)
      end
    end
  end
end
