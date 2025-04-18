require 'rails-settings-ui'

RailsSettingsUi.setup do |config|
  # Specify a controller for RailsSettingsUi::ApplicationController to inherit from:
  config.parent_controller = 'Admin::BaseController' # default: '::ApplicationController'

  config.settings_class = 'Settings::Db::Store'
end

Rails.application.config.to_prepare do
  # If you use a *custom layout*, make route helpers available to RailsSettingsUi:
  # RailsSettingsUi.inline_engine_routes!
  RailsSettingsUi::ApplicationController.module_eval do
    # Render RailsSettingsUi inside a custom layout
    # (set to 'application' to use app layout, default is RailsSettingsUi's own layout)
    layout 'admin'
  end
end