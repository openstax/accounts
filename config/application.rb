require_relative 'boot'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Accounts
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    config.i18n.available_locales = %w(en pl)
    config.i18n.fallbacks = [I18n.default_locale]
    # Suppress a warning
    # config.i18n.enforce_available_locales = true

    config.accounts = ActiveSupport::OrderedOptions.new
    # configure how long a login token is valid for
    config.accounts.default_login_token_expiration_period = 2.days
    # configure how long a password is valid for
    config.accounts.default_password_expiration_period = nil

    # Use the ExceptionsController to rescue routing/bad request exceptions
    # https://coderwall.com/p/w3ghqq/rails-3-2-error-handling-with-exceptions_app
    config.exceptions_app = ->(env) { ExceptionsController.action(:rescue_from).call(env) }

    # Use delayed_job for background jobs
    config.active_job.queue_adapter = :delayed_job

    redis_secrets = secrets[:redis]

    # Generate the Redis URL from the its components if unset
    redis_secrets[:url] ||= "redis#{'s' if redis_secrets[:password].present?}://#{
      ":#{redis_secrets[:password]}@" if redis_secrets[:password].present? }#{
      redis_secrets[:host]}#{":#{redis_secrets[:port]}" if redis_secrets[:port].present?}/#{
      "/#{redis_secrets[:db]}" if redis_secrets[:db].present?}"

    config.cache_store = :redis_store, {
      url: redis_secrets[:url],
      namespace: redis_secrets[:namespaces][:cache],
      expires_in: 90.minutes,
      compress: true,
    }

    def is_real_production?
      secrets[:environment_name] == 'production'
    end

    # https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#new-framework-defaults
    config.active_record.belongs_to_required_by_default = false
    config.autoload_paths += %W(#{config.root}/lib)

    # Use specific layouts for different DoorKeeper activities
    config.to_prepare do
      # Only Applications list
      Doorkeeper::ApplicationsController.layout "admin"
      # Only Authorization endpoint
      Doorkeeper::AuthorizationsController.layout "application"
      # Only Authorized Applications
      Doorkeeper::AuthorizedApplicationsController.layout "application"
      # Include ApplicationHelpers from this app to use with Doorkeeper
      # include only the ApplicationHelper module
      Doorkeeper::ApplicationController.helper ApplicationHelper
      # include all helpers from your application
      Doorkeeper::ApplicationController.helper Accounts::Application.helpers
    end
  end
end
