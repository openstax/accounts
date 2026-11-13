Sentry.init do |config|
  secrets = Rails.application.secrets

  config.dsn = secrets.sentry[:dsn]
  config.environment = secrets.environment_name
  config.release = secrets.release_version

  config.breadcrumbs_logger = %i[sentry_logger active_support_logger http_logger]

  # Don't attach request bodies, cookies, IP addresses or headers to events
  config.send_default_pii = false

  # Don't send transaction data to Sentry
  config.traces_sample_rate = 0.0

  # Reduce the amount of logging from Sentry
  config.logger = Sentry::Logger.new(STDOUT)
  config.logger.level = Logger::ERROR
end if Rails.env.production?
