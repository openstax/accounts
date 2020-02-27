# Organizes Accounts' use of global settings in the database and in Redis.
# Database settings are managed by the rails-settings-cached gem and are
# accessed through the UI using the rails-settings-ui gem.  Redis settings
# don't have a UI component currently.
#
# Individual files in `lib/settings` give wrapped access to these values
# (to separate us from thinking about where the values are stored, and
# also to give us an easy place to mock these settings in tests)
#
# Those wrappers hide direct access to the underlying data stores, which
# are...
#
#   Settings::Db.store
#   Settings::Redis.store

module Settings
  module Db
    class Store < RailsSettings::Base
      source Rails.root.join("config/app.yml")
      namespace Rails.env

      # Workaround (this method missing in current implementation, but RailsSettings-UI
      # expects it -- doesn't really need to use it any more b/c RailsSettingsCached
      # deals with defaults internally)
      def self.defaults
        result = RailsSettings::Default.enabled? ? RailsSettings::Default.instance : {}
        result.with_indifferent_access
      end
    end

    mattr_accessor :store
    self.store = Store
  end

  module Redis
    mattr_accessor :store
    if ! is_assets_precompile?
      redis_secrets = Rails.application.secrets[:redis]
      self.store = ::Redis::Store.new(
        url: redis_secrets[:url],
        namespace: redis_secrets[:namespaces][:settings]
      )
    end  
  end
end

# Load the settings wrappers
Dir[File.join(__dir__, 'settings', '*.rb')].each{ |file| require file }
