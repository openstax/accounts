Raven.configure do |config|
  secrets = Rails.application.secrets

  config.dsn = secrets.sentry[:dsn]
  config.current_environment = secrets.environment_name

  # Send POST data and cookies to Sentry
  config.processors -= [ Raven::Processor::Cookies, Raven::Processor::PostData ]
  config.release = secrets.release_version

  # Don't log "Sentry is ready" message
  config.silence_ready = true
end if Rails.env.production?
