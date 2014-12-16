# Load the rails application
require File.expand_path('../application', __FILE__)

require 'markdown_wrapper'
require 'settings'
require 'sign_in_state'
require 'omniauth/strategies/custom_identity'

SITE_NAME = 'OpenStax Accounts'
TEAM_NAME = 'OpenStax' # used when talking about our team
COPYRIGHT_HOLDER = 'Rice University'

# Initialize the rails application
Accounts::Application.initialize!
