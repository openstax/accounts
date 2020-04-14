require 'rails_helper'

RSpec.describe Doorkeeper::AuthorizationsController, type: :controller do
  before { controller.sign_in! user }

  context '#create' do
    context 'when feature flag is OFF ' do
      context 'user without a profile' do
        let(:user) { FactoryBot.create :user, state: :needs_profile }

        it 'redirects to /signup/profile' do
          post :create, params: { response_type: :code }
          expect(response).to redirect_to signup_profile_url
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

    context 'when feature flag is ON' do
      before do
        turn_on_student_feature_flag
      end

      context 'user without a profile' do
        let(:user) { FactoryBot.create :user, state: :needs_profile }

        it 'redirects to /signup/profile' do
          post :create, params: { response_type: :code }
          expect(response).to redirect_to signup_profile_url
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
