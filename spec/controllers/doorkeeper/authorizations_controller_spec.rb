require 'rails_helper'

RSpec.describe Doorkeeper::AuthorizationsController, type: :controller do
  before { controller.sign_in! user }

  context '#create' do
    context 'user without a profile' do
      let(:user) { FactoryBot.create :user, state: :needs_profile }

      xit 'redirects to /signup/profile' do
        post :create, params: { response_type: :code }
        expect(response).to redirect_to signup_profile_url
      end
    end

    context 'user with a profile' do
      let(:user) { FactoryBot.create :user }

      xit 'does not redirect' do
        post :create, params: { response_type: :code }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
