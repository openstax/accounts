secrets = Rails.application.secrets

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both thread web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_files = false

  # Compress JavaScripts and CSS
  config.assets.js_compressor = Uglifier.new(harmony: true)
  # config.assets.css_compressor = :sass

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Set to :debug to see everything in the log.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id, :remote_ip]

  config.action_mailer.delivery_method = :ses
  config.action_mailer.default_url_options = { protocol: 'https', host: secrets[:email_host] }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  redis_secrets = secrets[:redis]

  # Generate the Redis URL from the its components if unset
  redis_secrets[:url] ||= "redis#{'s' if redis_secrets[:password].present?}://#{
    ":#{redis_secrets[:password]}@" if redis_secrets[:password].present? }#{
    redis_secrets[:host]}#{":#{redis_secrets[:port]}" if redis_secrets[:port].present?}/#{
    "/#{redis_secrets[:db]}" if redis_secrets[:db].present?}"

  config.cache_store = :redis_store, {
    url:        redis_secrets[:url],
    namespace:  redis_secrets[:namespaces][:cache],
    expires_in: 90.minutes,
    compress:   true
  }

  # Lograge configuration (one-line logs in production)
  config.lograge.enabled = true
  config.log_tags = [ :remote_ip ]
  config.lograge.custom_options = lambda do |event|
    params = event.payload[:params].reject do |k|
      %w[controller action format].include? k
    end
    { "params" => params }
  end
  config.lograge.ignore_actions = ["static_pages#status"]
end
