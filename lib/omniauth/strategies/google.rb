module OmniAuth
  module Strategies
    class Google

      include OmniAuth::Strategy
      
      option :path_prefix, '/auth'
      option :name, 'google'
    end
  end
end
