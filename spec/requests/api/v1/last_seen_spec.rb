require 'rails_helper'

# Proves the before_action wired in config/initializers/controllers.rb reaches
# Api::V1::UsersController, which serves /api/user and does NOT inherit from
# ApplicationController -- the whole reason record_last_seen is hooked at the
# ActionController::Base initializer rather than in ApplicationController.
describe 'last_seen_at tracking via /api/user', type: :request, api: true, version: :v1 do
  let!(:user) { FactoryBot.create :user_with_emails, :terms_agreed }

  def sign_in_with_sso_cookie(user)
    secrets = Rails.application.secrets.sso[:cookie]
    cookies[secrets[:name]] = SsoCookie.generate(value: { sub: SsoCookie.user_hash(user) })
  end

  it 'stamps last_seen_at when a signed-in session hits GET /api/user' do
    sign_in_with_sso_cookie(user)

    expect do
      api_get '/user', nil, params: { always_200: 'true' }
    end.to change { user.reload.last_seen_at }.from(nil)

    expect(response).to have_http_status(:ok)
  end

  it 'does not stamp anything for an anonymous request' do
    expect do
      api_get '/user', nil, params: { always_200: 'true' }
    end.not_to change { user.reload.last_seen_at }
  end
end
