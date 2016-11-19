require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Accounts
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.accounts = ActiveSupport::OrderedOptions.new
    # configure how long a reset password link is valid for
    config.accounts.default_reset_code_expiration_period = 2.days
    # configure how long a password is valid for
    config.accounts.default_password_expiration_period = nil

    # Suppress a warning
    config.i18n.enforce_available_locales = true

    # Case-insensitive database indices for PostgreSQL
    # schema_plus_core and transaction_isolation monekeypatches conflict with each other,
    # but loading schema_plus_pg_indexes late seems to fix this
    # So we use require: false for it in the Gemfile
    config.after_initialize{ require 'schema_plus_pg_indexes' }

    # Use the ExceptionsController to rescue routing/bad request exceptions
    # https://coderwall.com/p/w3ghqq/rails-3-2-error-handling-with-exceptions_app
    config.exceptions_app = ->(env) { ExceptionsController.action(:rescue_from).call(env) }

    # Use delayed_job for background jobs
    config.active_job.queue_adapter = :delayed_job

    # Opting in to future behavior to get rid of deprecation warnings
    config.active_record.raise_in_transactional_callbacks = true

    redis_secrets = secrets['redis']
    config.cache_store = :redis_store, {
      url: redis_secrets['url'],
      namespace: redis_secrets['namespaces']['cache'],
      expires_in: 90.minutes
    }
  end
end
