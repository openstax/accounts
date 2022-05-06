require 'simplecov'
require 'codecov'
require 'parallel_tests'

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

  # Send merged result to codecov only if on CI (will generate HTML report by default locally)
  SimpleCov.formatter = SimpleCov::Formatter::Codecov if ENV.fetch('CI', nil) == 'true'

  # Merge coverage reports (and maybe send to codecov)
  SimpleCov::ResultMerger.merged_result.format!
end

# Start calculating code coverage
unless ENV['NO_COVERAGE']
  SimpleCov.start('rails') { merge_timeout 3600 }
end

ENV['RAILS_ENV'] = 'test'

require 'spec_helper'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/email/rspec'
require 'shoulda/matchers'

require 'openstax/salesforce/spec_helpers'
include OpenStax::Salesforce::SpecHelpers

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.include CaptureStdoutHelper
  config.include FeatureHelper

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.prepend_before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.prepend_before(:all) do
    metadata                 = self.class.metadata
    # rubocop
    DatabaseCleaner.strategy = metadata[:js] || metadata[:truncation] ? :truncation : :transaction
    DatabaseCleaner.start
  end

  config.prepend_before(:each) do
    DatabaseCleaner.start
  end

  # https://github.com/DatabaseCleaner/database_cleaner#rspec-with-capybara-example says:
  #   "It's also recommended to use append_after to ensure DatabaseCleaner.clean
  #    runs after the after-test cleanup capybara/rspec installs."
  config.append_after(:each) do
    DatabaseCleaner.clean
  end

  config.append_after(:all) do
    DatabaseCleaner.clean
  end
end

"""
Config for Capybara
"""
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--lang=en')
  Capybara::Selenium::Driver.new app, browser: :chrome, capabilities: [options]
end
# no-sandbox and disable-gpu are required for Chrome to work with Travis
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--no-sandbox')
  options.add_argument('--headless')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--disable-extensions')
  options.add_argument('--disable-infobars')
  Capybara::Selenium::Driver.new app, browser: :chrome, capabilities: [options]
end

CAPYBARA_PROTOCOL = DEV_PROTOCOL
CAPYBARA_PORT = ENV.fetch('PORT', DEV_PORT)
Capybara.javascript_driver = if EnvUtilities.load_boolean(name: 'HEADLESS', default: true)
                               :selenium_chrome_headless
                             else
                               :selenium_chrome
                             end
CAPYBARA_HOST = DEV_HOST
CAPYBARA_HOST_REGEX = /\A(.*\.)?#{Regexp.escape CAPYBARA_HOST.sub('*.', '').chomp('.*')}\z/
Capybara.asset_host = "#{CAPYBARA_PROTOCOL}://#{CAPYBARA_HOST}:#{CAPYBARA_PORT}"
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
