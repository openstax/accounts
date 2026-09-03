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
# selenium-webdriver is `require: false` in the Gemfile so non-feature runs don't pay
# for it; feature specs need it in every environment. Selenium Manager (>= 4.11)
# resolves a matching chromedriver on demand, which is what replaced the webdrivers
# gem and its networked `Chromedriver.update` behind a shared lockfile.
require 'selenium-webdriver'

# Chrome's built-in password manager will, after the first successful password
# submission in a browser session, start offering to save/autofill credentials on
# that origin. In our headless test runs this silently intercepts the next login
# form's password field: Capybara's fill_in reports success, but Chrome's autofill
# UI clears/overwrites the field a moment later, leaving it blank and the (JS-
# disabled-until-filled) submit button stuck disabled. Since Capybara reuses one
# browser process across many examples, this reliably breaks the *second and later*
# login in a run -- not the first -- which is why it presented as sporadic flakiness
# across unrelated specs (annual_check_in, pose_terms, student_signup_flow) rather
# than a single reproducible failure. Disable the password manager/leak-detection
# entirely for test runs.
CHROME_TEST_PREFS = {
  'credentials_enable_service' => false,
  'profile.password_manager_enabled' => false,
  'profile.password_manager_leak_detection' => false
}.freeze

# https://robots.thoughtbot.com/headless-feature-specs-with-chrome
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new args: [ 'lang=en' ]
  CHROME_TEST_PREFS.each { |name, value| options.add_preference(name, value) }

  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

# no-sandbox and disable-gpu are required for Chrome to work with Travis
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new args: [
    'no-sandbox', 'headless', 'disable-dev-shm-usage',
    'disable-gpu', 'disable-extensions', 'disable-infobars'
  ]
  CHROME_TEST_PREFS.each { |name, value| options.add_preference(name, value) }

  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

CAPYBARA_PROTOCOL = DEV_PROTOCOL
CAPYBARA_PORT = ENV.fetch('PORT', DEV_PORT)

if in_docker?
  Capybara.register_driver :selenium_chrome_headless_in_docker do |app|
      # `options:`, not the `desired_capabilities:` selenium 4 dropped.
      options = Selenium::WebDriver::Chrome::Options.new(
        args: %w[no-sandbox headless disable-gpu]
      )
      CHROME_TEST_PREFS.each { |name, value| options.add_preference(name, value) }

      Capybara::Selenium::Driver.new(app,
                                     browser: :remote,
                                     url: ENV['HUB_URL'],
                                     options: options)
  end

  Capybara.javascript_driver = :selenium_chrome_headless_in_docker

  # Normally the Capybara host is 'localhost', but within Docker it may not be.
  CAPYBARA_HOST = IPSocket.getaddress(Socket.gethostname)

  Capybara.asset_host = "#{CAPYBARA_PROTOCOL}://#{CAPYBARA_HOST}:#{CAPYBARA_PORT}"
  Capybara.app_host = "#{CAPYBARA_PROTOCOL}://#{CAPYBARA_HOST}:#{CAPYBARA_PORT}"
  Capybara.server_host = CAPYBARA_HOST
  Capybara.server_port = CAPYBARA_PORT
else
  if EnvUtilities.load_boolean(name: 'HEADLESS', default: true)
    # Run the feature specs in a full browser (note, this takes over your computer's focus)
    Capybara.javascript_driver = :selenium_chrome_headless
  else
    Capybara.javascript_driver = :selenium_chrome
  end

  CAPYBARA_HOST = DEV_HOST

  Capybara.asset_host = "#{CAPYBARA_PROTOCOL}://#{CAPYBARA_HOST}:#{CAPYBARA_PORT}"
end

# Defined outside the branches above: the before(:each) hook below references it for
# every example, so leaving it in the non-docker branch made every example raise
# NameError under docker.
CAPYBARA_HOST_REGEX = /\A(.*\.)?#{Regexp.escape CAPYBARA_HOST.sub('*.', '').chomp('.*')}\z/

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
