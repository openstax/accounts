require 'rails_helper'

# The external user credentials page (Assignments' "recovery credentials" flow)
# links to the OmniAuth request phase, and its own URL carries the user's JWE
# access token. OmniAuth used to copy that Referer into the cookie session,
# overflowing it (Sentry ACCOUNTS-49R).
RSpec.describe 'Newflow social auth request phase', type: :request do
  let(:user)      { FactoryBot.create :user, :terms_agreed, state: User::EXTERNAL }
  let(:token)     { FactoryBot.create :doorkeeper_access_token, resource_owner_id: user.id }
  let(:return_to) { 'https://assignments.openstax.org/recovery-credentials-complete' }

  let(:credentials_page_url) do
    "http://www.example.com/accounts/external_user_credentials/new?#{
      { token: token.token, return_to: return_to }.to_query
    }"
  end

  def session_cookie
    response.headers['Set-Cookie'].to_s[/#{SessionStoreCookieName}=[^;]*/].to_s
  end

  before do
    get credentials_page_url
  end

  %w[googlenewflow facebooknewflow].each do |provider|
    context provider do
      let!(:auth_path) do
        Nokogiri::HTML(response.body).at_css("a[href*='/i/auth/#{provider}?']")['href']
      end

      it 'does not store the referring URL (and its access token) in the session' do
        get auth_path, headers: { 'HTTP_REFERER' => credentials_page_url }

        expect(response).to have_http_status(:redirect)
        expect(session['omniauth.origin']).to be_nil
        expect(session['omniauth.state']).to be_present
        # Was ~2.8KB in test (production tokens are larger); the limit is 4KB
        expect(session_cookie.bytesize).to be < 2048
      end

      it 'does not overflow the cookie with a production-sized token in the Referer' do
        long_referer = credentials_page_url.sub(token.token, token.token * 5)

        expect { get auth_path, headers: { 'HTTP_REFERER' => long_referer } }.not_to raise_error

        expect(response).to have_http_status(:redirect)
      end

      it 'clears an origin left behind by an abandoned attempt' do
        get "/accounts/i/auth/#{provider}", params: { origin: 'login_form' }
        expect(session['omniauth.origin']).to eq 'login_form'

        get auth_path, headers: { 'HTTP_REFERER' => credentials_page_url }
        expect(session['omniauth.origin']).to be_nil
      end
    end
  end
end
