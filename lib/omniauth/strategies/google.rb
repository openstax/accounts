class Google < OmniAuth::Strategies::GoogleOauth2
  option :path_prefix, '/auth'
  option :name, 'google'
end
