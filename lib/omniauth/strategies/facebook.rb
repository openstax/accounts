class Facebook < OmniAuth::Strategies::Facebook
  option :path_prefix, 'auth'
  option :name, 'facebook'
end
