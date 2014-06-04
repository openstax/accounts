# Load the secret settings file
SECRET_SETTINGS = OpenStax::Utilities::Settings.load_settings(__FILE__,
                    '../config', 'secret_settings.yml')
