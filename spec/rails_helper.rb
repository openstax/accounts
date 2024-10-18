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
Capybara.register_driver :playwright_chromium do |app|
  Capybara::Playwright::Driver.new app, browser_type: :chromium, args: [ '--lang=en' ]
end

Capybara.register_driver :playwright_chromium_headless do |app|
  Capybara::Playwright::Driver.new app, browser_type: :chromium, args: [
    '--disable-dev-shm-usage',
    '--disable-extensions',
    '--disable-gpu',
    '--disable-infobars',
    '--headless',
    '--lang=en',
    '--no-sandbox',
  ]
end

if EnvUtilities.load_boolean(name: 'HEADLESS', default: true)
  # Run the feature specs in a full browser (note, this takes over your computer's focus)
  Capybara.javascript_driver = :playwright_chromium_headless
else
  Capybara.javascript_driver = :playwright_chromium
end

CAPYBARA_PROTOCOL = DEV_PROTOCOL
CAPYBARA_HOST = DEV_HOST
CAPYBARA_HOST_REGEX = /\A(.*\.)?#{Regexp.escape CAPYBARA_HOST.sub('*.', '').chomp('.*')}\z/
CAPYBARA_PORT = ENV.fetch('PORT', DEV_PORT)

Capybara.asset_host = "#{CAPYBARA_PROTOCOL}://#{CAPYBARA_HOST}:#{CAPYBARA_PORT}"

Capybara.server = :puma, { Silent: true } # To clean up your test output

# Normalize whitespaces
Capybara.default_normalize_ws = true

Capybara.configure do |config|
  config.default_max_wait_time = 15
end

RSpec.configure do |config|
  config.include ActiveJob::TestHelper

  # Whitelist the capybara host (which can change)
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
