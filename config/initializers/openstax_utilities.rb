OpenStax::Utilities.configure do |config|
  config.status_authenticate = -> do
    unless signed_in?
      # Due to the path_prefixer gem, main_app.login_path is wrong and thus authenticate_user!
      # redirects to the wrong URL here. Relative redirects are also broken.
      uri = Addressable::URI.parse(request.url)
      uri.path = uri.path.sub('/status', '/login')
      redirect_to uri.to_s
      next
    end

    next if !Rails.application.secrets.environment_name == 'production' ||
            current_user.is_administrator?

    raise SecurityTransgression
  end
  secrets = Rails.application.secrets
  config.environment_name = secrets.environment_name
  config.backend = 'accounts'
  config.release_version = secrets.release_version
  config.deployment = 'bit-deployment'
  config.deployment_version = secrets.deployment_version
end
