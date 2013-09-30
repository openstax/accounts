# Load the rails application
require File.expand_path('../application', __FILE__)

require "sign_in_state"
require "omniauth/strategies/custom_identity"

SITE_NAME = "OpenStax Services"
TEAM_NAME = "OpenStax" # used when talking about our team
COPYRIGHT_HOLDER = "Rice University"

# Initialize the rails application
Services::Application.initialize!
