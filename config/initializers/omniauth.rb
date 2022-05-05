# References:
#  http://stackoverflow.com/a/10417435/1664216

secrets = Rails.application.secrets

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, secrets[:facebook_app_id], secrets[:facebook_app_secret],
           scope: 'email,user_birthday,read_stream', display: 'popup'
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :identity,
           model: Identity,
           fields: %i[user_id password]
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, secrets[:google_client_id], secrets[:google_client_secret]
end

OmniAuth.config.allowed_request_methods = %i[get]

# fix protocol mismatch for non-prod environments
# https://github.com/zquestz/omniauth-google-oauth2#fixing-protocol-mismatch-for-redirect_uri-in-rails
OmniAuth.config.full_host = 'http://localhost:2999' unless Rails.env.production?


OmniAuth.config.logger = Rails.logger

# http://stackoverflow.com/a/11461558/1664216
# https://github.com/intridea/omniauth/wiki/FAQ
OmniAuth.config.on_failure = ->(env) {
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
