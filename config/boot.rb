# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

require 'rails/commands/server'

DEV_PORT = 2999
DEV_HOST = 'localhost'
DEV_URL_OPTIONS = { host: DEV_HOST, port: DEV_PORT }

module Rails
  class Server
    alias :default_options_alias :default_options
    def default_options
      default_options_alias.merge!(Host: DEV_HOST, Port: DEV_PORT)
    end
  end
end
