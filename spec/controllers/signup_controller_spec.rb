require 'rails_helper'

RSpec.describe SignupController, type: :controller do
  describe 'GET #welcome' do
    it 'renders welcome form/page' do
      get(:welcome)
      expect(response).to render_template(:welcome)
    end
  end

  context 'student' do
    describe 'GET #signup_form' do
      it 'renders student signup_form' do
        get(:signup_form, params: { role: 'student' })
        expect(response).to render_template(:signup_form)
      end
    end

    describe 'POST #signup_post' do
      before do
        load('db/seeds.rb') # create the FinePrint contracts
      end

      it 'calls SignupForm handler' do
        expect_any_instance_of(SignupForm).to receive(:call).once.and_call_original
        post(:signup_post)
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

        it 'saves unverified student user in the session' do
          expect_any_instance_of(described_class).to receive(:save_unverified_user) do |user|
            expect(user.role).to eq 'student'
          end.and_call_original
          post(:signup_post, params: params)
        end

        it 'creates a security log' do
          expect {
            post(:signup_post, params: params)
          }.to change {
            SecurityLog.where(event_type: :sign_up_successful, user: User.last)
          }
        end

        it 'redirects to verify_email_by_pin_form_path' do
          post(:signup_post, params: params)
          expect(response).to  redirect_to(verify_email_by_pin_form_path)
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
          post(:signup_post, params: params)

          expect(response).to render_template(:signup_form)
          expect(assigns(:"handler_result").errors).to  be_present
        end

        it 'creates a security log' do
          EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new(expecting: false)

          expect {
            post(:signup_post, params: params)
          }.to change {
            SecurityLog.sign_up_failed.count
          }
        end
      end
    end

    describe 'POST #change_signup_email' do
      before do
        create_user('original@openstax.org')
      end

      context 'success' do
        let(:params) {
          {
            change_signup_email: {
              email: 'newemail@openstax.org'
            }
          }
        }

        it 'redirects to verify_email_by_pin_form_path' do
          user = User.last
          user.update_attribute('state', 'unverified')
          session[:unverified_user_id] = user.id
          post(:change_signup_email_post, params: params)
          expect(response).to redirect_to(verify_email_by_pin_form_path)
        end
      end

      context 'failure' do
        params = {
          change_signup_email: {
            email: '' # cause a failure
          }
        }

        it 'renders change_signup_email_form' do
          user = User.last
          user.update_attribute('state', 'unverified')
          session[:unverified_user_id] = user.id

          post(:change_signup_email_post, params: params)
          expect(response).to render_template(:change_signup_email_form)
        end
      end
    end

    describe 'GET #verify_email_by_pin_form' do
      it 'renders email_verification_form unless missing unverified_user' do
        get(:verify_email_by_pin_form)
        expect(response).to redirect_to signup_path

        user = create_user('user@openstax.org')
        user.update_attribute('state', 'unverified')
        session[:unverified_user_id] = user.id

        get(:verify_email_by_pin_form)
        expect(response).to render_template(:email_verification_form)
      end
    end

    describe 'GET #change_signup_email_form' do
      it 'renders OK' do
        user = create_user('user@openstax.org')
        allow_any_instance_of(described_class).to receive(:unverified_user) { user }
        get('change_signup_email_form')
        expect(response.status).to eq(200)
        expect(response).to render_template(:change_signup_email_form)
      end

      it 'redirects when there is no unverified_user present' do
        get('change_signup_email_form')
        expect(response.status).to eq(302)
      end
    end
  end

  context 'educator' do
    describe 'GET #signup_form' do
      it 'renders educator signup_form' do
        get(:signup_form, params: { role: 'educator' })
        expect(response).to render_template(:signup_form)
      end
    end

    describe 'POST #signup' do
      before do
        load('db/seeds.rb') # create the FinePrint contracts
      end

      it 'calls SignupForm' do
        expect_any_instance_of(SignupForm).to receive(:call).once.and_call_original
        post(:signup_post)
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

        it 'saves unverified educator user in the session' do
          expect_any_instance_of(described_class).to receive(:save_unverified_user) do |user|
            expect(user.role).to eq 'educator'
          end.and_call_original
          post(:signup_post, params: params)
        end

        it 'creates a security log' do
          expect {
            post(:signup_post, params: params)
          }.to change {
            SecurityLog.where(event_type: :sign_up_successful, user: User.last)
          }
        end

        it 'redirects to verify_email_by_pin_form_path' do
          post(:signup_post, params: params)
          expect(response).to  redirect_to(verify_email_by_pin_form_path)
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
          post(:signup_post, params: params)

          expect(response).to render_template(:signup_form)
          expect(assigns(:"handler_result").errors).to  be_present
        end

        it 'creates a security log' do
          EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new(expecting: false)

          expect {
            post(:signup_post, params: params)
          }.to change {
            SecurityLog.sign_up_failed.count
          }
        end
      end
    end

    describe 'POST #change_signup_email' do
      before do
        user = create_user('original@openstax.org')
        user.update_attribute('state', 'unverified')
        allow_any_instance_of(described_class).to receive(:unverified_user).and_return(user)
      end

      context 'success' do
        let(:params) {
          {
            change_signup_email: {
              email: 'newemail@openstax.org'
            }
          }
        }

        it 'redirects to verify_email_by_pin_form_path' do
          user = User.last
          post(:change_signup_email_post, params: params)
          expect(response).to redirect_to(verify_email_by_pin_form_path)
        end
      end

      context 'failure' do
        params = {
          change_signup_email: {
            email: '' # cause a failure
          }
        }

        it 'renders change_signup_email_form' do
          user = User.last

          post(:change_signup_email_post, params: params)
          expect(response).to render_template(:change_signup_email_form)
        end
      end
    end

    describe 'GET #verify_email_by_pin_form' do
      context 'with current incomplete educator' do
        before { allow_any_instance_of(described_class).to receive(:unverified_user).and_return(user) }

        let(:user) { FactoryBot.create(:user_with_emails, state: User::UNVERIFIED) }

        it 'renders correct template' do
          get(:verify_email_by_pin_form)
          expect(response).to render_template(:email_verification_form)
        end
      end
    end

    describe 'GET #change_signup_email_form' do
      it 'renders OK' do
        user = create_user('user@openstax.org')
        user.update(state: User::UNVERIFIED)
        allow_any_instance_of(described_class).to receive(:unverified_user) { user }
        get('change_signup_email_form')
        expect(response.status).to eq(200)
        expect(response).to render_template(:change_signup_email_form)
      end

      it 'redirects when there is no unverified_user present' do
        get('change_signup_email_form')
        expect(response.status).to eq(302)
      end
    end
  end

  describe 'GET #signup_done' do
    before do
      user = FactoryBot.create(:user, :terms_agreed)
      mock_current_user(user)
    end

    it 'renders' do
      get(:signup_done)
      expect(response).to render_template(:signup_done)
    end
  end
end
