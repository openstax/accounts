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

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # config.time_zone = 'Central Time (US & Canada)'

    # localization
    config.i18n.default_locale = :en
    config.i18n.available_locales = %w(en pl)

    config.accounts = ActiveSupport::OrderedOptions.new
    # configure how long a login token is valid for
    config.accounts.default_login_token_expiration_period = 2.days
    # configure how long a password is valid for
    config.accounts.default_password_expiration_period = nil

    # Suppress a warning
    config.i18n.enforce_available_locales = true

    # Use the ExceptionsController to rescue routing/bad request exceptions
    # https://coderwall.com/p/w3ghqq/rails-3-2-error-handling-with-exceptions_app
    config.exceptions_app = ->(env) { ExceptionsController.action(:rescue_from).call(env) }

    # Use delayed_job for background jobs
    config.active_job.queue_adapter = :delayed_job

    redis_secrets = secrets[:redis]

    # Generate the Redis URL from the its components if unset
    redis_secrets[:url] ||= "redis#{'s' unless redis_secrets[:password].blank?}://#{
      ":#{redis_secrets[:password]}@" unless redis_secrets[:password].blank? }#{
      redis_secrets[:host]}#{":#{redis_secrets[:port]}" unless redis_secrets[:port].blank?}/#{
      "/#{redis_secrets[:db]}" unless redis_secrets[:db].blank?}"

    config.cache_store = :redis_store, {
      url: redis_secrets[:url],
      namespace: redis_secrets[:namespaces][:cache],
      expires_in: 90.minutes,
      compress: true,
    }

    def is_real_production?
      secrets.environment_name == 'production'
    end

    # https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#new-framework-defaults
    config.active_record.belongs_to_required_by_default = false
    config.autoload_paths += %W(#{config.root}/lib)
  end
end
