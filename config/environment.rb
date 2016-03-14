# Load the rails application
require File.expand_path('../application', __FILE__)

require 'markdown_wrapper'
require 'settings'
require 'sign_in_state'
require 'contracts_not_required'
require 'omniauth/strategies/custom_identity'

SITE_NAME = 'OpenStax Accounts'
PAGE_TITLE_SUFFIX = SITE_NAME
TEAM_NAME = 'OpenStax' # used when talking about our team
COPYRIGHT_HOLDER = 'Rice University'

# Initialize the rails application
Accounts::Application.initialize!
