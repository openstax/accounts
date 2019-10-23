# References:
#  http://stackoverflow.com/a/10417435/1664216

secrets = Rails.application.secrets

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, secrets[:facebook_app_id], secrets[:facebook_app_secret],
           client_options: {
             site: 'https://graph.facebook.com/v3.3',
             authorize_url: "https://www.facebook.com/v3.3/dialog/oauth"
           }

  provider(
    'facebooknewflow',
    secrets[:facebook_app_id],
    secrets[:facebook_app_secret],
    client_options: {
      site: 'https://graph.facebook.com/v3.3',
      authorize_url: "https://www.facebook.com/v3.3/dialog/oauth"
    }
  )

  provider :twitter, secrets[:twitter_consumer_key], secrets[:twitter_consumer_secret]
  provider :google_oauth2, secrets[:google_client_id], secrets[:google_client_secret]
  provider :custom_identity
end

OmniAuth.config.logger = Rails.logger

# http://stackoverflow.com/a/11461558/1664216
# https://github.com/intridea/omniauth/wiki/FAQ
OmniAuth.config.on_failure = ->(env) {
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
