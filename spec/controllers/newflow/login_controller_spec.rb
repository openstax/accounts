require 'rails_helper'

module Newflow
  describe LoginController, type: :controller do
    before { turn_on_educator_feature_flag }

    describe 'GET #login_form' do
      example 'success' do
        get(:login_form)
        expect(response).to have_http_status(:success)
      end
    end

    # Where an educator who abandoned signup lands when they come back. Two
    # populations reach this: the ones who never finished SheerID (no lead in
    # Salesforce at all -- the webhook returns on the error step before pushing
    # one) and the ones who did but never finished step 4 (a lead stamped
    # incomplete_signup). They have to resume at different steps.
    describe 'POST #login resuming an abandoned educator signup' do
      let(:params) { { login_form: { email: 'edu@openstax.org', password: 'password' } } }

      let(:educator) do
        user = create_newflow_user('edu@openstax.org', 'password', nil, nil, 'instructor')
        user.update!(is_profile_complete: false)
        user
      end

      it 'sends someone who never finished SheerID back to step 3' do
        educator.update!(sheerid_verification_id: nil, is_sheerid_unviable: false)

        post('login', params: params)

        expect(response).to redirect_to(educator_sheerid_form_path)
      end

      it 'sends someone who finished SheerID on to step 4' do
        educator.update!(sheerid_verification_id: 'a-verification-id')

        post('login', params: params)

        expect(response).to redirect_to(educator_profile_form_path)
      end

      it 'sends someone who opted out of SheerID on to step 4' do
        educator.update!(sheerid_verification_id: nil, is_sheerid_unviable: true)

        post('login', params: params)

        expect(response).to redirect_to(educator_profile_form_path)
      end

      it 'does not drag a finished educator back into signup' do
        educator.update!(sheerid_verification_id: 'a-verification-id', is_profile_complete: true)

        post('login', params: params)

        expect(response).not_to redirect_to(educator_sheerid_form_path)
        expect(response).not_to redirect_to(educator_profile_form_path)
      end
    end

    describe 'POST #login' do
      describe 'success' do
        describe 'students' do
          before do
            user = create_newflow_user('user@openstax.org', 'password')
            user.update!(role: User::STUDENT_ROLE)
            expect_any_instance_of(LogInUser).to receive(:call).once.and_call_original
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

          it 'includes redirect URL in security log message when present' do
            redirect_url = "https://openstax.org/books/biology-2e"
            # GET login_form with `?r=URL` stores the url
            get('login_form', params: { r: redirect_url })

            post('login', params: params)

            log = SecurityLog.where(event_type: :sign_in_successful).last
            expect(log.event_data['redirect']).to eq(redirect_url)
          end

          it 'does not include redirect URL in security log message when absent' do
            post('login', params: params)

            log = SecurityLog.where(event_type: :sign_in_successful).last
            expect(log.event_data['message']).to be_nil
          end
        end

        describe 'educators' do
          let(:user) { create_newflow_user('user@openstax.org', 'password') }

          before do
            user.update!(role: User::INSTRUCTOR_ROLE)
          end

          let(:params) do
            { login_form: { email: 'user@openstax.org', password: 'password' } }
          end

          context 'when educator is profile complete' do
            before { user.update!(is_profile_complete: true) }

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

            it 'includes redirect URL in security log message when present' do
              redirect_url = "https://openstax.org/books/chemistry-2e"
              # GET login_form with `?r=URL` stores the url
              get('login_form', params: { r: redirect_url })

              post('login', params: params)

              log = SecurityLog.where(event_type: :sign_in_successful).last
              expect(log.event_data['redirect']).to eq(redirect_url)
            end

            it 'does not include redirect URL in security log message when absent' do
              post('login', params: params)

              log = SecurityLog.where(event_type: :sign_in_successful).last
              expect(log.event_data['message']).to be_nil
            end
          end

          context 'when educator is NOT profile complete' do
            before { user.update!(is_profile_complete: false) }
            it 'does a redirect' do
              post('login', params: params)
              expect(response).to have_http_status(:redirect)
            end
          end
        end
      end

      describe 'failure' do
        describe 'when cannot_find_user' do
          let(:noones_email){ 'noone@openstax.org' }

          it 'creates a security log' do
            expect {
              post('login', params: { login_form: { email: noones_email, password: 'password' } })
            }.to change {
              SecurityLog.sign_in_failed.where(event_data: { reason: :cannot_find_user, email: noones_email}).count
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
                  email: email.value
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
  end
end
