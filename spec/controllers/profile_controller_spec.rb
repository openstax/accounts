require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
  describe 'GET #profile' do
    context 'when logged in' do
      before do
        user.update!(role: :instructor)
        mock_current_user(user)
      end

      let(:user) { create_newflow_user('user@openstax.org') }

      context 'when profile is complete' do
        before do
          user.update!(is_profile_complete: true)
        end

          it 'renders 200 OK status' do
          get(:profile)
          expect(response.status).to eq(200)
        end

        it 'renders profile_newflow' do
          get(:profile)
          expect(response).to render_template(:profile_newflow)
        end
      end

      context 'when profile is not complete' do
        before { user.update!(is_profile_complete: false) }

        it 'redirects to step 4 — complete profile form' do
          get(:profile)
          expect(response).to redirect_to(educator_profile_form_path)
        end
      end
    end

    context 'while not logged in' do
      it 'redirects to login form' do
        get(:profile)
        expect(response).to redirect_to login_path
      end
    end
  end
end
