VALID_IFRAME_ORIGINS = (SECRET_SETTINGS[:valid_iframe_origins] || []).map do |origin|
  Regexp.new("\\A#{origin}")
end


OpenStax::Api.configure do |config|

  config.user_class_name = 'User'
  config.current_user_method = 'current_user'

  config.validate_cors_origin = lambda do |request|
    VALID_IFRAME_ORIGINS.any? do | origin |
      origin.match(request.headers["HTTP_ORIGIN"])
    end
  end

end
