# Load the Rails application
require File.expand_path('../application', __FILE__)

require 'token_maker'
require 'locale_selector'
require 'markdown_wrapper'
require 'sign_in_state'
require 'sign_up_state'
require 'contracts_not_required'
require 'require_recent_signin'
require 'json_serialize'
require 'lookup_users'
require 'omniauth/strategies/custom_identity'
require 'salesforce/client'
require 'salesforce/user_missing'
require 'salesforce/contact'
require 'salesforce/lead'

SITE_NAME = 'OpenStax Accounts'
PAGE_TITLE_SUFFIX = SITE_NAME
TEAM_NAME = 'OpenStax' # used when talking about our team
COPYRIGHT_HOLDER = 'Rice University'

# Initialize the Rails application
Rails.application.initialize!
