class Googlenewflow < OmniAuth::Strategies::GoogleOauth2
  option :path_prefix, '/i/auth'
  option :name, 'googlenewflow'
end
