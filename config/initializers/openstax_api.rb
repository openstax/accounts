OpenStax::Api.configure do |config|

  config.user_class_name = 'User'
  config.current_user_method = 'current_user'

  config.validate_cors_origin = ->(request) { Host.trusted? request.headers["HTTP_ORIGIN"] }

end
