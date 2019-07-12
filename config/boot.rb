
# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __dir__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
# require 'bootsnap/setup' # TODO

# require 'rails/commands/server'  # TODO: BRYAN - remove this?

DEV_PORT = 2999
DEV_HOST = 'localhost'
DEV_URL_OPTIONS = { host: DEV_HOST, port: DEV_PORT }

# module Rails
#   class Server
#     def default_options
#       default_options_alias.merge!(Host: DEV_HOST, Port: DEV_PORT)
#     end
#     alias :default_options_alias :default_options
#   end
# end
