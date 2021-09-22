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
    # config.i18n.default_locale = :de
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

    def self.is_assets_precompile?
      ARGV[0] != "assets:precompile"
    end

    def is_assets_precompile?
      self.class.is_assets_precompile?
    end

    # Use delayed_job for background jobs
    config.active_job.queue_adapter = :delayed_job
    if Rails.application.is_assets_precompile?
      redis_secrets = secrets[:redis]
      config.cache_store = :redis_store, {
        url: redis_secrets[:url],
        namespace: redis_secrets[:namespaces][:cache],
        expires_in: 90.minutes,
        compress: true,
      }
    end

    def is_real_production?
      secrets.environment_name == "prodtutor"
    end

    def is_assets_precompile?
      ARGV[0] != "assets:precompile"
    end

    config.after_initialize do
      Doorkeeper::TokensController.class_eval do
        alias_method :original_create, :create # before_action not available
        def create
          ScoutHelper.ignore!(0.99)
          original_create
        end
      end
    end

    # https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#new-framework-defaults
    config.active_record.belongs_to_required_by_default = false
    config.autoload_paths += %W(#{config.root}/lib)
  end
end
