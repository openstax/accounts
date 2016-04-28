OpenStax::Api.configure do |config|

  config.user_class_name = 'User'

    config.validate_cors_origin = lambda do |request|
      true
    end


end
