Rails.application.config.middleware.use OmniAuth::Builder do
  provider :identity, :fields => [], on_failed_registration: lambda { |env|      
    IdentitiesController.action(:new).call(env)  
  }
  provider :facebook, SECRET_SETTINGS[:facebook_app_id], SECRET_SETTINGS[:facebook_app_secret]
  provider :twitter, SECRET_SETTINGS[:twitter_consumer_key], SECRET_SETTINGS[:twitter_consumer_secret]
end

OmniAuth.config.logger = Rails.logger