module OmniAuth
  module Strategies
    # See lib/omniauth/strategies/facebooknewflow.rb for why this needs the OmniAuth::Strategies
    # namespace under omniauth 2.x.
    class Googlenewflow < OmniAuth::Strategies::GoogleOauth2
      option :path_prefix, '/i/auth'
      option :name, 'googlenewflow'
    end
  end
end
