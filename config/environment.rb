# Load the rails application
require File.expand_path('../application', __FILE__)

require "sign_in_state"
require "settings"
require "extend_builtins"
require "omniauth/strategies/custom_identity"

DEV_HOST = "localhost:#{DEV_PORT}"
SITE_NAME = "OpenStax Accounts"
TEAM_NAME = "OpenStax" # used when talking about our team
COPYRIGHT_HOLDER = "Rice University"

# Initialize the rails application
Accounts::Application.initialize!
