require 'rails-settings-ui'

RailsSettingsUi.parent_controller = 'Admin::BaseController' # default: '::ApplicationController'
RailsSettingsUi::ApplicationController.layout 'admin'
RailsSettingsUi.settings_class = "Settings::Db::Store"

Rails.application.config.to_prepare do
  # If you use a *custom layout*, make route helpers available to RailsSettingsUi:
  RailsSettingsUi.inline_main_app_routes!
end
