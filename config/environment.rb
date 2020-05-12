# Load the Rails application
require_relative 'application'

require 'scout_helper'
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
require 'fetch_book_data'
require 'rate_limiting'
require 'omniauth/strategies/custom_identity'
require "omniauth/strategies/facebooknewflow"
require "omniauth/strategies/googlenewflow"
require 'email_address_validations'
require 'subjects_utils'
require 'host'
require 'sso_cookie_jar'
require 'set_gdpr_data'
require 'date_time'

SITE_NAME = 'OpenStax Accounts'
PAGE_TITLE_SUFFIX = SITE_NAME
TEAM_NAME = 'OpenStax' # used when talking about our team
COPYRIGHT_HOLDER = 'Rice University'

# Initialize the Rails application
Rails.application.initialize!
