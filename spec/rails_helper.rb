ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../../config/environment', __FILE__)
# Add additional requires below this line. Rails is not loaded until this point!
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
require 'openstax/salesforce/spec_helpers'
require 'rspec/rails'
require 'webdrivers'
require 'capybara/rails'
require 'capybara/email/rspec'
require 'shoulda/matchers'
require 'parallel_tests'
require 'simplecov'
require 'codecov'
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
    'no-sandbox', 'headless', 'disable-dev-shm-usage', 'disable-gpu', 'disable-extensions', 'disable-infobars'
  ]

  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

Capybara.javascript_driver = :selenium_chrome_headless

Capybara.asset_host = 'http://localhost:2999'

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
  Config for Simplecov
"""
# Deactivate automatic result merging, because we use custom result merging code
SimpleCov.use_merging false

# Custom result merging code to avoid the many partial merges that SimpleCov usually creates
# and send to codecov only once
SimpleCov.at_exit do
  # Store the result for later merging
  SimpleCov::ResultMerger.store_result(SimpleCov.result)

  # All processes except one will exit here
  next unless ParallelTests.last_process?

  # Wait for everyone else to finish
  ParallelTests.wait_for_other_processes_to_finish

  if ENV['CI'] == 'true'
    # Send merged result to codecov only if on CI (will generate HTML report by default locally)
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
    Rails.application.eager_load!
  end

  # Merge coverage reports (and maybe send to codecov)
  SimpleCov::ResultMerger.merged_result.format!
end

# Start calculating code coverage
SimpleCov.start('rails') { merge_timeout 3600 }

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
class ExternalAppForSpecsController < ActionController::Base
  skip_filter *_process_action_callbacks.map(&:filter)
  layout false

  def index
    render plain: 'This is a fake external application'
  end
end
