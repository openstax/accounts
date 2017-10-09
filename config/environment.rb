# Load the Rails application
require File.expand_path('../application', __FILE__)

require 'env_utilities'
require 'token_maker'
require 'locale_selector'
require 'markdown_wrapper'
require 'user_session_management'
require 'authenticate_methods'
require 'contracts_not_required'
require 'require_recent_signin'
require 'json_serialize'
require 'lookup_users'
require 'rate_limiting'
require 'omniauth/strategies/custom_identity'
require 'email_address_validations'
require 'subjects_utils'

SITE_NAME = 'OpenStax Accounts'
PAGE_TITLE_SUFFIX = SITE_NAME
TEAM_NAME = 'OpenStax' # used when talking about our team
COPYRIGHT_HOLDER = 'Rice University'

# Initialize the Rails application
Rails.application.initialize!
