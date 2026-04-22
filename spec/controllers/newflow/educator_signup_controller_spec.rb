require 'rails_helper'

module Newflow
  describe EducatorSignupController, type: :controller do
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
            SecurityLog.where(event_type: :educator_began_signup, user: User.last).count
          }
        end

        it 'includes redirect URL in security log message when present' do
          redirect_url = "https://openstax.org/books/chemistry-2e"
          # GET educator_signup_form with `?r=URL` stores the url
          get(:educator_signup_form, params: { r: redirect_url })

          post(:educator_signup, params: params)

          log = SecurityLog.where(event_type: :educator_began_signup).last
          expect(log.event_data['redirect']).to eq(redirect_url)
        end

        it 'does not include redirect URL in security log message when absent' do
          post(:educator_signup, params: params)

          log = SecurityLog.where(event_type: :educator_began_signup).last
          expect(log.event_data['redirect']).to be_nil
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

      context 'when recaptcha is disabled' do
        let(:params) do
          {
            signup: {
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
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

        before do
          allow(Settings::Recaptcha).to receive(:disabled?) { true }
        end

        it 'bypasses recaptcha verification and allows signup' do
          expect_any_instance_of(described_class).not_to receive(:verify_recaptcha)
          post(:educator_signup, params: params)
          expect(response).to redirect_to(educator_email_verification_form_path)
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
          expect_any_instance_of(described_class).not_to receive(:verify_recaptcha)
          post(:educator_change_signup_email, params: params)
          expect(response).to redirect_to(educator_email_verification_form_updated_email_path)
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

    describe 'PostHog event for educator_complete_profile' do
      render_views
      let(:user) { create_newflow_user('educator@openstax.org', 'password', nil, nil, 'instructor') }

      before do
        disable_sfdc_client if defined?(disable_sfdc_client)
        allow(OXPosthog).to receive(:log)
        controller.sign_in! user
      end

      it 'includes expected_start_semester in the props hash' do
        post :educator_complete_profile, params: {
          signup: {
            school_name: 'Test School',
            educator_specific_role: 'instructor',
            using_openstax_how: 'as_primary',
            who_chooses_books: 'instructor',
            books_used: ['Algebra and Trigonometry'],
            books_used_details: {
              'Algebra and Trigonometry' => {
                'num_students_using_book' => '30',
                'how_using_book' => 'As the core textbook for my course'
              }
            },
            expected_start_semester: 'this_semester'
          }
        }

        expect(OXPosthog).to have_received(:log).with(
          kind_of(User),
          'educator_complete_profile',
          hash_including(expected_start_semester: 'this_semester')
        )
      end

      it 'sends nil for users on the as_future path' do
        post :educator_complete_profile, params: {
          signup: {
            school_name: 'Test School',
            educator_specific_role: 'instructor',
            using_openstax_how: 'as_future',
            who_chooses_books: 'instructor',
            books_of_interest: ['Algebra and Trigonometry'],
            books_used: [],
            expected_start_semester: 'this_semester'
          }
        }

        expect(OXPosthog).to have_received(:log).with(
          kind_of(User),
          'educator_complete_profile',
          hash_including(expected_start_semester: nil)
        )
      end
    end

    describe 'GET #educator_profile_form renders the expected_start_semester fieldset' do
      render_views
      let(:user) { create_newflow_user('educator2@openstax.org', 'password', nil, nil, 'instructor') }

      before do
        user.update!(is_profile_complete: false)
        controller.sign_in! user
      end

      context 'when the feature flag is off' do
        before { allow(Settings::FeatureFlags).to receive(:expected_start_semester_enabled).and_return(false) }

        it 'does not render the expected_start_semester fieldset' do
          get :educator_profile_form
          expect(response.body).not_to include(I18n.t(:"educator_profile_form.expected_start_semester"))
          expect(response.body).not_to include('signup[expected_start_semester]')
        end
      end

      context 'when the feature flag is on' do
        before { allow(Settings::FeatureFlags).to receive(:expected_start_semester_enabled).and_return(true) }

        it 'renders the expected_start_semester fieldset and the four options' do
          get :educator_profile_form
          expect(response.body).to include(I18n.t(:"educator_profile_form.expected_start_semester"))
          expect(response.body).to include('signup[expected_start_semester]')
          expect(response.body).to include('This semester')
          expect(response.body).to include('Next semester')
          expect(response.body).to include('Next academic year')
          expect(response.body).to include('Just exploring')
        end

        it 'renders the fieldset with display:none so JS shows it conditionally (Task 8)' do
          get :educator_profile_form
          expect(response.body).to match(/<fieldset[^>]*class="[^"]*expected-start-semester[^"]*"[^>]*style="display: none;?"/)
        end
      end
    end
  end
end
