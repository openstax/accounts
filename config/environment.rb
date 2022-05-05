# Load the Rails application
require_relative 'application'

require 'authenticate_methods'
require 'contracts_not_required'
require 'date_time'
require 'email_address_validations'
require 'env_utilities'
require 'fetch_book_data'
require 'host'
require 'json_serialize'
require 'lookup_users'
require 'markdown_wrapper'
require 'rate_limiting'
require 'require_recent_signin'
require 'scout_helper'
require 'set_gdpr_data'
require 'sheerid_api'
require 'sso_cookie_jar'
require 'token_maker'
require 'user_session_management'

SITE_NAME = 'OpenStax Accounts'
PAGE_TITLE_SUFFIX = SITE_NAME
TEAM_NAME = 'OpenStax' # used when talking about our team
COPYRIGHT_HOLDER = 'Rice University'

UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

# Initialize the Rails application
Rails.application.initialize!
