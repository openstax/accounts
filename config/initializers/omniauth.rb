# References:
#  http://stackoverflow.com/a/10417435/1664216

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, SECRET_SETTINGS[:facebook_app_id], SECRET_SETTINGS[:facebook_app_secret]
  provider :twitter, SECRET_SETTINGS[:twitter_consumer_key], SECRET_SETTINGS[:twitter_consumer_secret]
  provider :google_oauth2, SECRET_SETTINGS[:google_client_id], SECRET_SETTINGS[:google_client_secret]
  provider :custom_identity
end

OmniAuth.config.logger = Rails.logger

# http://stackoverflow.com/a/11461558/1664216
# https://github.com/intridea/omniauth/wiki/FAQ
OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

