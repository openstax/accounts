ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# Logger must be required before ActiveSupport loads logger_thread_safe_level.rb,
# which references Logger::Severity. Ruby 3.1+ no longer auto-loads it.
require 'logger'

# Ruby 3.2 removed File.exists? (deprecated alias of File.exist? since 2.1).
# compass, compass-core, action_interceptor, fine_print, maruku, and
# openstax_salesforce all still call it (mostly from rake tasks). Shimming
# it back in here is far smaller than forking/patching six gems. Delete
# this once all of them have dropped the call (check with
# `grep -rl 'File\.exists?' $(bundle show --paths)`).
File.singleton_class.alias_method(:exists?, :exist?)

require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

require_relative 'dev_url_options'
