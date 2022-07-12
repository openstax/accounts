class GoogleOAuth2 < OmniAuth::Strategies::GoogleOauth2
  option :path_prefix, 'auth'
  option :name, 'google_oauth2'
end
