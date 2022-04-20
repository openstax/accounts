require 'rails_helper'

RSpec.describe SignupController, type: :controller do
  describe 'GET #welcome' do
    it 'renders welcome form/page' do
      get(:welcome)
      expect(response).to render_template(:welcome)
    end
  end

  describe 'GET #signup_form' do
    it 'renders signup form for student' do
      get(:signup_form, params: { role: 'student' })
      expect(response).to render_template(:signup_form)
    end

    it 'renders signup form for educator' do
      get(:signup_form, params: { role: 'educator' })
      expect(response).to render_template(:signup_form)
    end
  end

  describe 'POST #signup_post' do
    before do
      load('db/seeds.rb') # create the FinePrint contracts
    end

    it 'calls Handlers::SignupForm' do
      expect_any_instance_of(SignupForm).to receive(:call).once.and_call_original
      post(:signup_post)
    end

    context 'success' do
      let(:params) do
        {
          signup: {
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.first_name,
            email: 'user2@openstax.org',
            password: 'password',
            newsletter: false,
            terms_accepted: true,
            contract_1_id:  FinePrint::Contract.first.id,
            contract_2_id:  FinePrint::Contract.second.id,
            role: :student
          }
        }
      end

      it 'saves unverified user in the session' do
        expect_any_instance_of(described_class).to receive(:save_unverified_user).and_call_original
        post(:signup_post, params: params)
      end

      it 'creates a security log' do
        expect {
          post(:signup_post, params: params)
        }.to change {
          SecurityLog.where(event_type: :sign_up_successful, user: User.last)
        }
      end

      it 'redirects to student_email_verification_form_path' do
        post(:signup_post, params: params)
        expect(response).to redirect_to(:verify_email_by_pin_form)
      end
    end

    context 'failure' do
      let(:params) do
        {
          signup: {
            first_name: Faker::Name.first_name,
            last_name:  Faker::Name.first_name,
            email: '1', # invalid email will cause it to fail
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
        expect(assigns(:"handler_result").errors).to be_present
      end

      it 'creates a security log' do
        EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new(expecting: false)

        expect {
          post(:signup_post, params: params)
        }.to change {
          SecurityLog.user_signup_failed.count
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

      it 'redirects to email_verification_form_updated_email_path' do
        user = User.last
        user.update_attribute(:state, :unverified)
        session[:unverified_user_id] = user.id

        post(:change_signup_email_post, params: params)
        expect(response).to redirect_to(:change_signup_email_form_complete)
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

        post(:change_signup_email_post, params: params)
        expect(response).to render_template(:change_signup_email_form)
      end
    end
  end

  describe 'GET #student_email_verification_form' do
    it 'renders email_verification_form unless missing unverified_user' do
      get(:verify_email_by_pin_form_path)
      expect(response).to redirect_to signup_path

      user = create_user('user@openstax.org')
      user.update_attribute('state', 'unverified')
      session[:unverified_user_id] = user.id

      get(:verify_email_by_pin_form)
      expect(response).to render_template(:verify_email_by_pin)
    end
  end

  describe 'GET #student_email_verification_form_updated_email' do
    it 'renders OK' do
      user = create_user('user@openstax.org')
      allow_any_instance_of(described_class).to receive(:unverified_user) { user }
      get(:verify_email_by_pin_form)
      expect(response.status).to eq(200)
      expect(response).to render_template(:email_verification_form)
    end

    it 'redirects when there is no unverified_user present' do
      user = nil
      session[:unverified_user_id] = nil
      get(:verify_email_by_pin_form)
      expect(response.status).to eq(302)
    end
  end

  describe 'GET #signup_done' do
    before do
      user = FactoryBot.create(:user)
      mock_current_user(user)
    end

    it 'renders' do
      get(:signup_done)
      expect(response).to render_template(:signup_done)
    end
  end
end
