SECRET_SETTINGS = OpenStax::Utilities::Settings.load_settings(
  __FILE__, '../config', 'secret_settings.yml'
)

DEPLOY_SETTINGS = OpenStax::Utilities::Settings.load_settings(
  __FILE__, '../config', 'deploy_settings.yml'
)
