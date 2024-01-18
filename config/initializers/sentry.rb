Sentry.init do |config|
  secrets = Rails.application.secrets

  config.dsn = secrets.sentry[:dsn]
  config.environment = secrets.environment_name
  config.release = secrets.release_version

  config.breadcrumbs_logger = %i[sentry_logger active_support_logger http_logger]

  # Send POST data and cookies to Sentry
  config.send_default_pii = true

  # Reduce the amount of logging from Sentry
  config.logger = Sentry::Logger.new(STDOUT)
  config.logger.level = Logger::ERROR
end if Rails.env.production?
