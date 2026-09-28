module OmniAuth
  module Strategies
    # omniauth 2.x's OmniAuth::Builder#provider resolves string provider names via
    # `OmniAuth::Strategies.const_get(name, false)` (the `false` disallows falling back to
    # top-level constants, unlike omniauth 1.x), so this strategy must live in the
    # OmniAuth::Strategies namespace to be found by name (see config/initializers/omniauth.rb).
    class Facebooknewflow < OmniAuth::Strategies::Facebook
      option :path_prefix, '/i/auth'
      option :name, 'facebooknewflow'
    end
  end
end
