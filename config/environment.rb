# Load the Rails application
require_relative 'application'

# require 'scout_helper'
# require 'env_utilities'
# require 'token_maker'
# require 'markdown_wrapper'
# require 'user_session_management'
# require 'authenticate_methods'
# require 'contracts_not_required'
# require 'require_recent_signin'
# require 'json_serialize'
# require 'lookup_users'
# require 'fetch_book_data'
# require 'sheerid_api'
# require 'rate_limiting'
# require 'omniauth/strategies/custom_identity'
# require "omniauth/strategies/facebook"
# require "omniauth/strategies/google_oauth2"
# require 'email_address_validations'
# require 'host'
# require 'sso_cookie_jar'
# require 'set_gdpr_data'
# require 'date_time'

SITE_NAME = 'OpenStax Accounts'
PAGE_TITLE_SUFFIX = SITE_NAME
TEAM_NAME = 'OpenStax' # used when talking about our team
COPYRIGHT_HOLDER = 'Rice University'

UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

# Initialize the Rails application
Rails.application.initialize!
