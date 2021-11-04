# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations

DEV_PROTOCOL = 'http'
DEV_PORT = 2999
DEV_HOST = 'localhost'
DEV_URL_OPTIONS = { protocol: DEV_PROTOCOL, host: DEV_HOST, port: DEV_PORT }
