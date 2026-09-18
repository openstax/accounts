require 'rails_helper'

module Legacy
  describe AuthenticationsController, type: :controller do
    render_views

    let!(:user) { FactoryBot.create :user, :terms_agreed }

    describe 'GET #add' do
      context 'when the user signed in recently' do
        before { controller.sign_in! user } # sign_in! logs a fresh :sign_in_successful

        it 'renders a POST form that starts the omniauth request phase after an explicit submit' do
          get :add, params: { provider: 'facebook' }

          expect(response).to have_http_status(:ok)
          # POSTs (not GETs) into the request phase so omniauth 2.0 accepts it (CVE-2015-9284).
          # `add=true` rides in the query string because omniauth stores request.GET into
          # omniauth.params (see SessionsCreate), not the POST body.
          expect(response.body).to include('action="/auth/facebook?add=true"')
          expect(response.body).to include('method="post"')
          expect(response.body).to include('Continue to finish adding this login option to your account.')
          expect(response.body).to include('value="Continue"')
          # (The Rails CSRF token that omniauth-rails_csrf_protection validates is only emitted
          # when allow_forgery_protection is on, which is disabled in the test environment.)
        end
      end

      context 'when the last successful sign in is too old' do
        before do
          controller.sign_in! user
          SecurityLog.sign_in_successful.where(user: user).update_all(created_at: 20.minutes.ago)
        end

        it 'requires reauthentication instead of starting the request phase' do
          get :add, params: { provider: 'facebook' }
          expect(response).to have_http_status(:redirect)
        end
      end
    end
  end
end
