require 'rails_helper'

RSpec.describe LoginController, type: :controller do

  describe 'GET #login_form' do
    example 'success' do
      get(:login_form)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #login' do
    describe 'success' do
      describe 'students' do
        before do
          user = create_user('user@openstax.org', 'password')
          user.update!(role: :student)
          expect_any_instance_of(LogInUser).to receive(:call).once.and_call_original
        end

        let(:params) do
          { login_form: { email: 'user@openstax.org', password: 'password' } }
        end

        it 'logs in the user' do
          expect_any_instance_of(described_class).to receive(:sign_in!).once.and_call_original
          post(:login_post, params: params)
          expect(assigns(:current_user)).to eq(User.last)
        end

        it 'redirects on success' do
          post(:login_post, params: params)
          expect(response).to have_http_status(:redirect)
        end

        it 'redirects back to `r`eturn parameter' do
          path = Faker::Internet.slug

          # GET login_form with `?r=URL` stores the url to return to after login
          get(:login_form, params: { r: "https://openstax.org/#{path}" })

          post(:login_post, params: params)
          expect(response).to redirect_to("https://openstax.org/#{path}")
        end

        it 'checks `r`eturn parameter is whitelisted' do
          expect(Host).to receive(:trusted?).once.and_call_original
          # GET login_form with `?r=URL` may store a SAFE url to return to after login
          get(:login_form, params: { r: 'https://maliciousdomain.com' })

          post(:login_post, params: params)
          expect(response).not_to redirect_to('https://maliciousdomain.com')
        end

        it 'creates a security log' do
          expect {
            post(:login_post, params: params)
          }.to change {
            SecurityLog.where(event_type: :sign_in_successful).count
          }
        end
      end

      describe 'educators' do
        let(:user) { create_user('user@openstax.org', 'password') }

        before do
          user.update!(role: :instructor)
        end

        let(:params) do
          { login_form: { email: 'user@openstax.org', password: 'password' } }
        end

        context 'when educator is profile complete' do
          before { user.update!(is_profile_complete: true) }

          it 'logs in the user' do
            expect_any_instance_of(described_class).to receive(:sign_in!).once.and_call_original
            post(:login_post, params: params)
            expect(assigns(:current_user)).to eq(User.last)
          end

          it 'redirects on success' do
            post(:login_post, params: params)
            expect(response).to have_http_status(:redirect)
          end

          it 'redirects back to `r`eturn parameter' do
            path = Faker::Internet.slug

            # GET login_form with `?r=URL` stores the url to return to after login
            get(:login_form, params: { r: "https://openstax.org/#{path}" })

            post(:login_post, params: params)
            expect(response).to redirect_to("https://openstax.org/#{path}")
          end

          it 'checks `r`eturn parameter is whitelisted' do
            expect(Host).to receive(:trusted?).once.and_call_original
            # GET login_form with `?r=URL` may store a SAFE url to return to after login
            get('login_form', params: { r: 'https://maliciousdomain.com' })

            post(:login_post, params: params)
            expect(response).not_to redirect_to('https://maliciousdomain.com')
          end

          it 'creates a security log' do
            expect {
              post(:login_post, params: params)
            }.to change {
              SecurityLog.where(event_type: :sign_in_successful).count
            }
          end
        end

        context 'when educator is NOT profile complete' do
          before { user.update!(faculty_status: :incomplete_signup) }

          it 'saves incomplete educator in the session' do
            expect_any_instance_of(described_class).to receive(:save_incomplete_educator).with(user).once.and_call_original
            post(:login_post, params: params)
            expect(assigns(:current_incomplete_educator)).to eq(user)
          end

          it 'does a redirect' do
            post(:login_post, params: params)
            expect(response).to have_http_status(:redirect)
          end
        end
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
