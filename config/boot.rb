ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# Logger must be required before ActiveSupport loads logger_thread_safe_level.rb,
# which references Logger::Severity. Ruby 3.1+ no longer auto-loads it.
require 'logger'

require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

require_relative 'dev_url_options'
