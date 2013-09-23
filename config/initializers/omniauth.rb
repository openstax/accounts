# http://stackoverflow.com/a/10417435/1664216
module OmniAuth
  module Strategies
    class Identity
      # def request_phase
      #   redirect '/login'
      # end

      # def other_phase
      #   if on_registration_path?
      #     if request.get?
      #       re
      #     elsif request.post?
      #       registration_phase
      #     end
      #   else
      #     call_app!
      #   end
      # end
   end
 end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  # provider :identity, 
  #          fields: [:username, :first_name, :last_name], 
  #          # on_login: lambda {|env| SessionsController.action(:new).call(env)},
  #          on_failed_registration: lambda { |env|      
  #            IdentitiesController.action(:new).call(env)  
  #          },
  #          on_registration: lambda { |env|
  #            IdentitiesController.action(:new).call(env)
  #          },
  #          locate_conditions: lambda { |req|
  #            user = User.where(username: req.params['auth_key'])
  #            {user_id: (user.empty? ? nil : user.id)}
  #          }

  provider :custom_identity #, 
           # on_failed_registration: lambda { |env|      
           #   IdentitiesController.action(:new).call(env)  
           # },
           # locate_conditions: lambda { |req|
           #   user = User.where(username: req.params['auth_key'])
           #   {user_id: (user.empty? ? nil : user.id)}
           # }

  provider :facebook, SECRET_SETTINGS[:facebook_app_id], SECRET_SETTINGS[:facebook_app_secret]
  provider :twitter, SECRET_SETTINGS[:twitter_consumer_key], SECRET_SETTINGS[:twitter_consumer_secret]
end

OmniAuth.config.logger = Rails.logger

# http://stackoverflow.com/a/11461558/1664216
# https://github.com/intridea/omniauth/wiki/FAQ
OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

