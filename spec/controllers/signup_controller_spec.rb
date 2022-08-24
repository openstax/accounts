require 'rails_helper'

RSpec.describe SignupController, type: :controller do
  let(:valid_student_params) do
    {
      signup: {
        first_name: Faker::Name.first_name,
        last_name:  Faker::Name.last_name,
        email: Faker::Internet.safe_email,
        password: 'password',
        newsletter: false,
        terms_accepted: true,
        contract_1_id: FinePrint::Contract.first.id,
        contract_2_id: FinePrint::Contract.second.id,
        role: 'student'
      }
    }
  end

  let(:invalid_student_params) do
    {
      signup: {
        first_name: Faker::Name.first_name,
        last_name:  Faker::Name.last_name,
        email: 'invalid-email@..',
        password: 'password',
        newsletter: false,
        terms_accepted: true,
        contract_1_id: FinePrint::Contract.first.id,
        contract_2_id: FinePrint::Contract.second.id,
        role: 'student'
      }
    }
  end

  let(:valid_educator_params) do
    {
      signup: {
        first_name: Faker::Name.first_name,
        last_name:  Faker::Name.last_name,
        email: Faker::Internet.safe_email,
        password: 'password',
        phone_number: Faker::PhoneNumber.phone_number,
        newsletter: false,
        terms_accepted: true,
        contract_1_id: FinePrint::Contract.first.id,
        contract_2_id: FinePrint::Contract.second.id,
        role: 'instructor'
      }
    }
  end

  let(:invalid_educator_params) do
    {
      signup: {
        first_name: Faker::Name.first_name,
        last_name:  Faker::Name.last_name,
        email: 'invalid-email@..',
        password: 'password',
        phone_number: Faker::PhoneNumber.phone_number,
        newsletter: false,
        terms_accepted: true,
        contract_1_id: FinePrint::Contract.first.id,
        contract_2_id: FinePrint::Contract.second.id,
        role: 'instructor'
      }
    }
  end

  let(:valid_change_email_params) {
    {
      change_signup_email: {
        email: 'newemail@openstax.org'
      }
    }
  }

  let(:invalid_change_email_params) {
    {
      change_signup_email: {
        email: 'invalid-email'
      }
    }
  }

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
      it 'calls SignupForm handler' do
        expect_any_instance_of(SignupForm).to receive(:call).once.and_call_original
        post(:signup_post)
      end

      context 'success' do
        it 'creates a security log' do
          expect {
            post(:signup_post, params: valid_student_params)
          }.to change {
            SecurityLog.where(event_type: :sign_up_successful, user: User.last)
          }
        end

        it 'redirects to verify_email_by_pin_form_path' do
          post(:signup_post, params: valid_student_params)
          expect(response).to  redirect_to(verify_email_by_pin_form_path)
        end
      end

      context 'failure' do
        it 'renders student signup form with errors' do
          post(:signup_post, params: invalid_student_params)

          expect(response).to render_template(:signup_form)
          expect(assigns(:"handler_result").errors).to be_present
        end

        it 'creates a security log' do
          EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new(expecting: false)

          expect {
            post(:signup_post, params: invalid_student_params)
          }.to change {
            SecurityLog.sign_up_failed.count
          }
        end
      end
    end

    describe 'POST #change_signup_email' do
      before do
        post(:signup_post, params: valid_student_params)
        get(:change_signup_email_form)
      end

      context 'success' do
        it 'redirects to verify_email_by_pin_form_path' do
          get(:change_signup_email_form)
          expect(response).to render_template(:change_signup_email_form)
          post(:change_signup_email_post, params: valid_change_email_params)
          expect(response).to redirect_to(verify_email_by_pin_form_path)
        end
      end

      context 'failure' do
        it 'renders change_signup_email_form' do
          get(:change_signup_email_form)
          expect(response).to render_template(:change_signup_email_form)
          post(:change_signup_email_post, params: invalid_change_email_params)
          expect(response).to render_template(:change_signup_email_form)
        end
      end
    end

  end

  context 'instructor' do
    describe 'GET #signup_form' do
      it 'renders instructor signup_form' do
        get(:signup_form, params: { role: 'educator' })
        expect(response).to render_template(:signup_form)
      end
    end

    describe 'POST #signup' do
      it 'calls SignupForm' do
        expect_any_instance_of(SignupForm).to receive(:call).once.and_call_original
        post(:signup_post)
      end

      context 'success' do
        it 'creates a security log' do
          expect {
            post(:signup_post, params: valid_educator_params)
          }.to change {
            SecurityLog.where(event_type: :sign_up_successful, user: User.last)
          }
        end

        it 'redirects to verify_email_by_pin_form_path' do
          post(:signup_post, params: valid_educator_params)
          expect(response).to  redirect_to(verify_email_by_pin_form_path)
        end
      end

      context 'failure' do
        it 'renders instructor signup form with errors' do
          post(:signup_post, params: invalid_educator_params)

          expect(response).to render_template(:signup_form)
          expect(assigns(:"handler_result").errors).to  be_present
        end

        it 'creates a security log' do
          EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new(expecting: false)

          expect {
            post(:signup_post, params: invalid_educator_params)
          }.to change {
            SecurityLog.sign_up_failed.count
          }
        end
      end
    end

    describe 'POST #change_signup_email' do
      before do
        post(:signup_post, params: valid_educator_params)
        get(:change_signup_email_form)
      end

      context 'success' do
        it 'redirects to verify_email_by_pin_form_path' do
          post(:change_signup_email_post, params: valid_change_email_params)
          expect(response).to redirect_to(verify_email_by_pin_form_path)
        end
      end

      context 'failure' do
        it 'renders change_signup_email_form' do
          post(:change_signup_email_post, params: invalid_change_email_params)
          expect(response).to render_template(:change_signup_email_form)
        end
      end
    end

    describe 'GET #verify_email_by_pin_form' do
      context 'with current signing up educator' do
        let(:user) { FactoryBot.create(:user_with_emails, faculty_status: 'needs_email_verification') }

        it 'renders correct template' do
          get(:verify_email_by_pin_form)
          expect(response).to render_template(:email_verification_form)
        end
      end
    end

    describe 'GET #change_signup_email_form' do
      it 'renders the change email form template' do
        user = create_user('user@openstax.org')
        user.update(state: 'unverified', faculty_status: 'needs_email_verified')
        get(:change_signup_email_form)
        expect(response).to render_template(:change_signup_email_form)
      end

      it 'redirects when there is no user present' do
        get(:change_signup_email_form)
        expect(response.status).to eq(302)
        expect(response).to redirect_to(signup_path)
      end
    end
  end
end
