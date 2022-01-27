Sentry.init do |config|
  secrets = Rails.application.secrets

  config.dsn = secrets.sentry[:dsn]
  config.environment = secrets.environment_name
  config.release = secrets.release_version

  config.breadcrumbs_logger = %i[sentry_logger active_support_logger http_logger]
  config.traces_sample_rate = 0.5

  # Send POST data and cookies to Sentry
  config.send_default_pii = true
end if Rails.env.production?
