require 'rails_helper'

RSpec.describe Doorkeeper::AuthorizationsController, type: :controller do
  before { controller.sign_in! user }

  let(:app) { FactoryBot.create :doorkeeper_application }

  context '#create' do
    context 'when a student uses social auth' do
      context 'user without a profile' do
        let(:user) { FactoryBot.create :user, state: :needs_profile }

        it 'redirects to /signup/profile' do
          post :create, params: {
            client_id: app.uid, redirect_uri: app.redirect_uri, response_type: :code
          }
          expect(response).to redirect_to signup_profile_url
        end
      end

      context 'user with a profile' do
        let(:user) { FactoryBot.create :user, :terms_agreed }

        it 'redirects to the app, not to /signup/profile' do
          post :create, params: {
            client_id: app.uid, redirect_uri: app.redirect_uri, response_type: :code
          }
          expect(response).to redirect_to a_string_matching(app.redirect_uri)
        end
      end
    end
  end
end
