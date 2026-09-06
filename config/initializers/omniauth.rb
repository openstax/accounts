# References:
#  http://stackoverflow.com/a/10417435/1664216

secrets = Rails.application.secrets

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :custom_identity

  provider :facebook, secrets[:facebook_app_id], secrets[:facebook_app_secret],
           client_options: {
             site: 'https://graph.facebook.com/v19.0',
             authorize_url: "https://www.facebook.com/v19.0/dialog/oauth"
           }

  provider(
    'facebooknewflow',
    secrets[:facebook_app_id],
    secrets[:facebook_app_secret],
    client_options: {
      site: 'https://graph.facebook.com/v19.0',
      authorize_url: "https://www.facebook.com/v19.0/dialog/oauth"
    }
  )

  provider :google_oauth2, secrets[:google_client_id], secrets[:google_client_secret]

  provider 'googlenewflow', secrets[:google_client_id], secrets[:google_client_secret]

  provider :twitter, secrets[:twitter_consumer_key], secrets[:twitter_consumer_secret]
end

OmniAuth.config.logger = Rails.logger

# omniauth 2.0 (see https://github.com/omniauth/omniauth/wiki/Upgrading-to-2.0) defaults
# `allowed_request_methods` to `[:post]` only, closing CVE-2015-9284 (a GET-triggered request
# phase is forgeable via CSRF). We set it explicitly so the guarantee is visible and can't be
# silently widened. Every social-login trigger POSTs with a Rails authenticity token: the login/
# signup/reauth/external-credential views use `link_to ..., method: :post` (jquery_ujs), and the
# reauth-then-add flow renders an auto-submitting POST form (Legacy::AuthenticationsController#add
# -> app/views/legacy/authentications/add.html.erb). The omniauth-rails_csrf_protection gem
# validates those tokens in the request_validation_phase. Do NOT add :get back without reverting
# all of those call sites to plain GET links, which would reopen the CVE.
OmniAuth.config.allowed_request_methods = [:post]

# http://stackoverflow.com/a/11461558/1664216
# https://github.com/intridea/omniauth/wiki/FAQ
OmniAuth.config.on_failure = ->(env) {
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
