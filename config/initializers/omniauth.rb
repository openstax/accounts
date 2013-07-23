Rails.application.config.middleware.use OmniAuth::Builder do
  provider :identity, :fields => [], on_failed_registration: lambda { |env|      
    IdentitiesController.action(:new).call(env)  
  }
  provider :facebook, SECRET_SETTINGS[:facebook_app_id], SECRET_SETTINGS[:facebook_app_secret]
end

OmniAuth.config.logger = Rails.logger