require 'rails_helper'

RSpec.describe EducatorSignupController, type: :controller do
  before { turn_on_educator_feature_flag }

  describe 'GET #educator_signup_form' do
    it 'renders educator signup_form' do
      get(:educator_signup_form)
      expect(response).to  render_template(:educator_signup_form)
    end
  end

  describe 'POST #educator_signup' do
    before do
      load('db/seeds.rb') # create the FinePrint contracts
    end

    it 'calls Handlers::EducatorSignup::SignupForm' do
      expect_any_instance_of(EducatorSignup::SignupForm).to receive(:call).once.and_call_original
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

      it 'redirects to educator_email_verification_form_path' do
        post(:educator_signup, params: params)
        expect(response).to  redirect_to(educator_email_verification_form_path)
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

  describe 'POST #educator_change_signup_email' do
    before do
      user = create_newflow_user('original@openstax.org')
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

      it 'redirects to educator_email_verification_form_updated_email_path' do
        user = User.last
        post(:educator_change_signup_email, params: params)
        expect(response).to redirect_to(educator_email_verification_form_updated_email_path)
      end
    end

    context 'failure' do
      params = {
        change_signup_email: {
          email: '' # cause a failure
        }
      }

      it 'renders educator_change_signup_email_form' do
        user = User.last

        post(:educator_change_signup_email, params: params)
        expect(response).to render_template(:educator_change_signup_email_form)
      end
    end
  end

  describe 'GET #educator_email_verification_form' do
    context 'with current incomplete educator' do
      before { allow_any_instance_of(described_class).to receive(:unverified_user).and_return(user) }

      let(:user) { FactoryBot.create(:user_with_emails, state: User::UNVERIFIED) }

      it 'renders correct template' do
        get(:educator_email_verification_form)
        expect(response).to render_template(:educator_email_verification_form)
      end
    end
  end

  describe 'GET #educator_email_verification_form_updated_email' do
    it 'renders OK' do
      user = create_newflow_user('user@openstax.org')
      user.update(state: User::UNVERIFIED)
      allow_any_instance_of(described_class).to receive(:unverified_user) { user }
      get('educator_email_verification_form_updated_email')
      expect(response.status).to eq(200)
      expect(response).to render_template(:educator_email_verification_form_updated_email)
    end

    it 'redirects when there is no unverified_user present' do
      get('educator_email_verification_form_updated_email')
      expect(response.status).to eq(302)
    end
  end

  describe 'GET #educator_sheerid_form' do
    it 'requires a logged in user'
  end

  describe 'POST #sheerid_webhook' do
    let(:handler) { EducatorSignup::SheeridWebhook }

    let(:params) do
      { 'verificationId': Faker::Alphanumeric.alphanumeric(number: 24) }
    end

    it 'is processed by the lev handler' do
      expect(handler).to receive(:handle)

      post(:sheerid_webhook, params: params)
    end

    describe 'must be externally available' do
      before(:each) do
        allow(handler).to receive(:handle).and_return(true)
      end

      it 'is not forgery protected' do
        with_forgery_protection do
          expect_any_instance_of(ActionController::Base).not_to receive(:verify_authenticity_token)

          post(:sheerid_webhook, params: params)
        end
      end
    end
  end

  describe 'GET #educator_profile_form' do
    it 'renders'
  end

  describe 'POST #educator_complete' do
    it ''
  end

  describe 'POST #educator_verify_email_by_pin' do
    it ''
  end
end
