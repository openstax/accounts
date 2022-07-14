require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe 'GET #login_form' do
    example 'success' do
      get(:login_form)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #login' do
    describe 'success' do
      describe 'students' do
        let(:user) { create_newflow_user('user@openstax.org') }

        let(:params) do
          { login_form: { email: 'user@openstax.org', password: 'password' } }
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

          byebug

          post(:login_post, params: params)
          expect(response).not_to redirect_to('https://maliciousdomain.com')
        end
      end
    end
  end
end
