module OmniAuth
  module Strategies
    class Facebook
      NullSession = ActionController::RequestForgeryProtection::ProtectionMethods::NullSession

      include OmniAuth::Strategy

      option :path_prefix, '/auth'
      option :name, 'facebook'
    end
  end
end
