require 'rails_helper'

RSpec.describe Doorkeeper::AuthorizationsController, type: :controller do
  before { controller.sign_in! user }

  context '#create' do
    context 'when a student uses social auth' do
      context 'user without a profile' do
        let(:user) { FactoryBot.create :user, state: :needs_profile }

        it 'redirects to /profile' do
          post :create, params: { response_type: :code }
          expect(response).to redirect_to profile_newflow_url
        end
      end

      context 'user with a profile' do
        let(:user) { FactoryBot.create :user, :terms_agreed }

        it 'does not redirect' do
          post :create, params: { response_type: :code }
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
