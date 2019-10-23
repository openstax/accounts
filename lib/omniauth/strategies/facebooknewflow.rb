class Facebooknewflow < OmniAuth::Strategies::Facebook
  option :path_prefix, '/i/auth'
  option :name, 'facebooknewflow'
end
