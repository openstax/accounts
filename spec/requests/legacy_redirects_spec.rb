require 'rails_helper'

# Retired Legacy:: controllers were deleted and their routes now redirect to
# the equivalent newflow (`/i/...`) URL -- see config/routes.rb's
# `newflow_redirect` helper. These specs cover the representative compatibility
# behavior: that old bookmarked/linked URLs still work and that query-string
# params riding along (e.g. `r`, used for post-login redirect-back) survive
# the hop. PUT /profile is the one legacy path that stays "live" (not a
# redirect) because the newflow profile page's inline-editable fields PUT
# there directly -- see OtherController#update.
describe 'Legacy URL compatibility redirects', type: :request do
  describe 'GET /profile' do
    it 'redirects to /i/profile' do
      get '/profile'

      expect(response).to redirect_to('/i/profile')
    end
  end

  describe 'GET /login' do
    it 'redirects to /i/login, preserving the query string' do
      get '/login', params: { r: '/foo' }

      expect(response).to redirect_to('/i/login?r=%2Ffoo')
    end
  end

  describe 'GET /signup' do
    it 'redirects to /i/signup' do
      get '/signup'

      expect(response).to redirect_to('/i/signup')
    end
  end

  describe 'GET /logout' do
    it 'redirects to /i/signout' do
      get '/logout'

      expect(response).to redirect_to('/i/signout')
    end
  end

  describe 'PUT /profile' do
    let(:user) { create_newflow_user('user@openstax.org') }

    before { mock_current_user(user) }

    it 'routes to OtherController#update, not the retired legacy redirect' do
      put '/profile', params: { name: 'username', value: 'newusername' }, as: :json

      expect(response.status).to eq(200)
      expect(user.reload.username).to eq('newusername')
    end
  end
end
