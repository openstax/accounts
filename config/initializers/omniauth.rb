# http://stackoverflow.com/a/10417435/1664216
module OmniAuth
  module Strategies
   class Identity
     def request_phase
       redirect '/login'
     end
   end
 end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :identity, :fields => [], on_failed_registration: lambda { |env|      
    IdentitiesController.action(:new).call(env)  
  }
  provider :facebook, SECRET_SETTINGS[:facebook_app_id], SECRET_SETTINGS[:facebook_app_secret]
  provider :twitter, SECRET_SETTINGS[:twitter_consumer_key], SECRET_SETTINGS[:twitter_consumer_secret]
end

OmniAuth.config.logger = Rails.logger