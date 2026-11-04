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

        it 'sends a new PIN and returns to the PIN screen' do
          user = User.last
          user.update_attribute('state', 'unverified')
          user.email_addresses.first.update!(verified: false)
          session[:unverified_user_id] = user.id
          post(:student_change_signup_email, params: params)
          expect(response).to redirect_to(student_email_verification_form_path)
          expect(flash[:notice]).to eq I18n.t(
            :"login_signup_form.signup_email_changed", email: 'newemail@openstax.org'
          )
        end

        it 'resends under the resend limits when the same address is entered again' do
          user = User.last
          user.update_attribute('state', 'unverified')
          user.email_addresses.first.update!(verified: false, confirmation_sent_at: 10.seconds.ago)
          session[:unverified_user_id] = user.id

          expect {
            post(:student_change_signup_email, params: { change_signup_email: { email: 'original@openstax.org' } })
          }.not_to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)

          expect(response).to redirect_to(student_email_verification_form_path)
          expect(flash[:alert]).to eq I18n.t(:"login_signup_form.signup_email_resent_too_soon")
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
          user.email_addresses.first.update!(verified: false)
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
          user.email_addresses.first.update!(verified: false)
          session[:unverified_user_id] = user.id
          expect_any_instance_of(described_class).not_to receive(:verify_recaptcha)
          post(:student_change_signup_email, params: params)
          expect(response).to redirect_to(student_email_verification_form_path)
        end
      end
    end

    describe 'GET #student_email_verification_form' do
      it 'renders student_email_verification_form unless missing unverified_user' do
        get(:student_email_verification_form)
        expect(response).to redirect_to newflow_signup_path

        user = create_newflow_user('user@openstax.org')
        user.update_attribute('state', 'unverified')
          user.email_addresses.first.update!(verified: false)
        session[:unverified_user_id] = user.id

        get(:student_email_verification_form)
        expect(response).to render_template(:student_email_verification_form)
      end
    end

    describe 'POST #student_resend_signup_email' do
      let(:user) { FactoryBot.create(:user_with_emails, state: User::UNVERIFIED, emails_count: 1) }

      before do
        user.email_addresses.update_all(verified: false, confirmation_sent_at: nil)
        allow_any_instance_of(described_class).to receive(:unverified_user).and_return(user)
        allow(OXPosthog).to receive(:log)
      end

      it 'resends the email and returns to the PIN screen' do
        expect {
          post(:student_resend_signup_email)
        }.to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)

        expect(response).to redirect_to(student_email_verification_form_path)
        expect(flash[:notice]).to eq I18n.t(
          :"login_signup_form.signup_email_resent",
          email: ERB::Util.html_escape(user.email_addresses.first.value)
        )
        expect(OXPosthog).to have_received(:log).with(
          user, 'student_resent_signup_email', hash_including(role: user.role)
        )
      end

      it 'asks the user to wait when the email was just sent' do
        user.email_addresses.update_all(confirmation_sent_at: 10.seconds.ago)

        expect {
          post(:student_resend_signup_email)
        }.not_to have_enqueued_mail(NewflowMailer, :signup_email_confirmation)

        expect(flash[:alert]).to eq I18n.t(:"login_signup_form.signup_email_resent_too_soon")
      end

      it 'tells the user when the hourly limit is reached' do
        5.times { SecurityLog.create!(user: user, event_type: :signup_email_resent) }

        post(:student_resend_signup_email)

        expect(flash[:alert]).to eq I18n.t(:"login_signup_form.signup_email_resend_limit_reached")
      end

      it 'escapes the address in the notice, since the layout renders flash as html_safe' do
        user.email_addresses.update_all(value: 'a<b>@example.com')

        post(:student_resend_signup_email)

        expect(flash[:notice]).to include('a&lt;b&gt;@example.com')
      end
    end

    describe 'POST #student_verify_email_by_pin' do
      let(:user) { FactoryBot.create(:user_with_emails, state: User::UNVERIFIED, emails_count: 1) }

      before do
        user.email_addresses.update_all(verified: false)
        allow_any_instance_of(described_class).to receive(:unverified_user).and_return(user)
        allow(OXPosthog).to receive(:log)
      end

      it 'captures the failure with an allowlisted reason' do
        post(:student_verify_email_by_pin, params: { confirm: { pin: 'nope' } })

        expect(response).to render_template(:student_email_verification_form)
        expect(OXPosthog).to have_received(:log).with(
          user, 'student_verified_email_failed', { role: user.role, reason: 'pin_not_correct' }
        )
      end
    end

  end
end
