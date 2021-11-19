ENV['RAILS_ENV'] ||= 'test'

require 'simplecov_helper'
require File.expand_path('../../config/environment', __FILE__)
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
require 'openstax/salesforce/spec_helpers'
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/email/rspec'
require 'shoulda/matchers'
require 'parallel_tests'
require 'database_cleaner'
require 'spec_helper'

include OpenStax::Salesforce::SpecHelpers

# https://github.com/colszowka/simplecov/issues/369#issuecomment-313493152
# Load rake tasks so they can be tested.
Rails.application.load_tasks unless defined?(Rake::Task) && Rake::Task.task_defined?('environment')

# Check for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

# Fail on missing translation in a spec.
I18n.exception_handler = lambda do |exception, locale, key, options|
  raise "Missing translation for #{key} in locale #{locale} with options #{options}"
end

"""
  Config for Capybara
"""
# https://robots.thoughtbot.com/headless-feature-specs-with-chrome
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new args: [ 'lang=en' ]

  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

# no-sandbox and disable-gpu are required for Chrome to work with Travis
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new args: [
    'no-sandbox', 'headless', 'disable-dev-shm-usage',
    'disable-gpu', 'disable-extensions', 'disable-infobars'
  ]

  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

# The webdrivers gem uses selenium-webdriver.  Our docker approach needs selenium-webdriver
# but gets upset if webdriver is loaded.  So in the Gemfile, we `require: false` both of
# these and explicitly require them based on where we're running.  We also only register
# the docker flavor of the driver if we are indeed running in docker.

CAPYBARA_PROTOCOL = DEV_PROTOCOL
CAPYBARA_PORT = ENV.fetch('PORT', DEV_PORT)

if in_docker?
  require 'selenium-webdriver'

  Capybara.register_driver :selenium_chrome_headless_in_docker do |app|
      chrome_capabilities = ::Selenium::WebDriver::Remote::Capabilities.chrome(
        'goog:chromeOptions' => { 'args': %w[no-sandbox headless disable-gpu] }
      )

      Capybara::Selenium::Driver.new(app,
                                     browser: :remote,
                                     url: ENV['HUB_URL'],
                                     desired_capabilities: chrome_capabilities)
  end

  Capybara.javascript_driver = :selenium_chrome_headless_in_docker

  # Normally the Capybara host is 'localhost', but within Docker it may not be.
  CAPYBARA_HOST = IPSocket.getaddress(Socket.gethostname)

  Capybara.asset_host = "#{CAPYBARA_PROTOCOL}://#{CAPYBARA_HOST}:#{CAPYBARA_PORT}"
  Capybara.app_host = "#{CAPYBARA_PROTOCOL}://#{CAPYBARA_HOST}:#{CAPYBARA_PORT}"
  Capybara.server_host = CAPYBARA_HOST
  Capybara.server_port = CAPYBARA_PORT
else
  require 'webdrivers/chromedriver'

  if EnvUtilities.load_boolean(name: 'HEADLESS', default: true)
    # Run the feature specs in a full browser (note, this takes over your computer's focus)
    Capybara.javascript_driver = :selenium_chrome_headless
  else
    Capybara.javascript_driver = :selenium_chrome
  end

  CAPYBARA_HOST = DEV_HOST
  CAPYBARA_HOST_REGEX = /\A(.*\.)?#{Regexp.escape CAPYBARA_HOST.sub('*.', '').chomp('.*')}\z/

  Capybara.asset_host = "#{CAPYBARA_PROTOCOL}://#{CAPYBARA_HOST}:#{CAPYBARA_PORT}"
end

Capybara.server = :puma, { Silent: true } # To clean up your test output

# Normalize whitespaces
Capybara.default_normalize_ws = true

Capybara.configure do |config|
  config.default_max_wait_time = 15
end

# Whitelist the capybara host (which can change)
RSpec.configure do |config|
  config.before(:each) do
    allow(Host).to receive(:trusted_host_regexes).and_wrap_original do |m, *args|
      m.call(*args).tap do |result|
        result.push(CAPYBARA_HOST_REGEX) unless result.include?(CAPYBARA_HOST_REGEX)
      end
    end
  end
end

"""
  Config for Shoulda Matchers
"""
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

"""
  Custom helpers
"""
# http://stackoverflow.com/questions/16507067/testing-stdout-output-in-rspec
require 'stringio'

def capture_output(&blk)
  old_stdout = $stdout
  old_stderr = $stderr

  begin
    $stdout = StringIO.new
    $stderr = StringIO.new

    blk.call

    [$stdout.string, $stderr.string]
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end
end

# Adds a convenience method to get interpret the body as JSON and convert to a hash;
# works for both request and controller specs
class ActionDispatch::TestResponse
  def body_as_hash
    @body_as_hash_cache ||= JSON.parse(body, symbolize_names: true)
  end
end

def disable_sfdc_client
  allow(ActiveForce)
    .to receive(:sfdc_client)
    .and_return(double('null object').as_null_object)
end
