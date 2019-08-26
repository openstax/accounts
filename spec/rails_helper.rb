ENV['RAILS_ENV'] ||= 'test'

require 'simplecov_helper'
require File.expand_path('../../config/environment', __FILE__)
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
require 'openstax/salesforce/spec_helpers'
require 'rspec/rails'
require 'webdrivers'
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

Capybara.javascript_driver = :selenium_chrome_headless

Capybara.asset_host = 'http://localhost:2999'

# Normalize whitespaces
Capybara.default_normalize_ws = true

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
