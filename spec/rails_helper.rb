require 'simplecov'
require 'parallel_tests'
require 'codecov'

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
  SimpleCov.formatter = SimpleCov::Formatter::Codecov if ENV['CI'] == 'true'

  # Merge coverage reports (and maybe send to codecov)
  SimpleCov::ResultMerger.merged_result.format!
end

# Start calculating code coverage
SimpleCov.start('rails') { merge_timeout 3600 }

ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!

# https://github.com/colszowka/simplecov/issues/369#issuecomment-313493152
# Load rake tasks so they can be tested.
Rails.application.load_tasks unless defined?(Rake::Task) && Rake::Task.task_defined?('environment')

require 'openstax/salesforce/spec_helpers'
include OpenStax::Salesforce::SpecHelpers

require 'shoulda/matchers'

require 'selenium/webdriver'

# https://robots.thoughtbot.com/headless-feature-specs-with-chrome
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new args: [ 'lang=en' ]

  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

# no-sandbox and disable-dev-shm-usage are required for Chrome to work with Docker (Travis)
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new args: [
    'headless', 'no-sandbox', 'disable-dev-shm-usage', 'lang=en'
  ]

  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

Capybara.javascript_driver = :selenium_chrome_headless

Capybara.asset_host = 'http://localhost:2999'

require 'capybara/email/rspec'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  config.include I18nMacros

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, type: :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  # or set:
  #   config.infer_spec_type_from_file_location!
  config.infer_spec_type_from_file_location!

  config.prepend_before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.prepend_before(:all) do
    metadata = self.class.metadata
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

  # Some tests might change I18n.locale.
  config.before(:each) do |config|
    I18n.locale = :en
  end

  config.before(:each) do
    # Get rid of possibly-shared config setting cache values between test and dev or any leftover
    # cached values from other test runs. This is 15 seconds faster than `Rails.cache.clear`
    Rails.cache.delete_matched("rails_settings_cached/*")
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

# This method isn't great... seems to take too much
def just_text(string)
  ActionView::Base.full_sanitizer.sanitize(string).gsub(/\W*\n\W*/," \n ")
end

RSpec::Matchers.define :have_routine_error do |error_code|
  include RSpec::Matchers::Composable

  match do |actual|
    actual.errors.any?{|error| error.code == error_code}
  end

  failure_message do |actual|
    "expected that #{actual} would have error :#{error_code.to_s}"
  end
end

RSpec::Matchers.define :have_api_error_code do |error_code|
  include RSpec::Matchers::Composable

  match do |actual|
    actual.body_as_hash[:errors].any?{|error| error[:code] == error_code}
  end

  failure_message do |actual|
    "expected that response would have error '#{error_code.to_s}' but had #{actual.body_as_hash[:errors].map{|error| error[:code]}}"
  end
end

RSpec::Matchers.define :have_api_error_status do |error_status|
  include RSpec::Matchers::Composable

  match do |actual|
    actual.body_as_hash[:status] == error_status.to_i
  end

  failure_message do |actual|
    "expected that response would have status '#{
    error_status}' but had #{actual.body_as_hash[:status]}"
  end
end

# Matcher checking a model instance for error presence. For example
#
#   model = Model.create(id: already_taken_value, name: 'Name')
#   expect(model).to have_error(:id, :taken)
#   expect(model).not_to have_error(:name, :blank)
RSpec::Matchers.define :have_error do |field, message|
  include RSpec::Matchers::Composable

  match do |actual|
    actual.errors.types.include? field and actual.errors.types[field].include? message
  end

  failure_message do |actual|
    if actual.errors[field].empty?
      "expected #{actual.model_name} to have errors on #{field}, but it had none"
    else
      msg = error_msg actual.class, field, message
      "expected #{actual.errors[field]} to include #{msg.inspect}"
    end
  end

  failure_message_when_negated do |actual|
    msg = error_msg actual.class, field, message
    "expected #{actual.errors[field]} not to include #{msg.inspect}"
  end
end

# Utility for getting error messages for models. It's intended as a replacement
# for have_error matcher to be used when there is no model instance. For example
#
#   visit '/redefine/model/instance'
#   expect(page).to have_content(error_msg Model, :id, :taken)
#
# There two alternative signatures
#
# error_msg model, field, error, options = {}
# error_msg model, group, field, error, options = {}
#
# First form expects model to be an ActiveRecord model, a Lev handler with
# a single paramify block, or a symbol naming one.
#
# Second form expects a Lev handler with a paramify block named group, or
# a symbol naming one.
def error_msg model, *args
  model_or_name = model
  if model.is_a? Symbol
    model = Object.const_get model.to_s.camelize
  end

  if model.include? Lev::Handler
    if args[-1].is_a? Hash
      options = args.pop
    else
      options = {}
    end

    if args.length == 3
      group, field, error = args
    elsif args.length == 2 and model.paramify_classes.keys.length == 1
      field, error = args
      group = model.paramify_classes.keys[0]
    end

    model = model.paramify_classes[group]

    if model.nil?
      raise "#{model_or_name} is a Lev handler but is not paramified"
    end
  else
    field, error, options = args
  end
  options ||= {}

  instance = model.new
  if options.has_key? :value
    instance[field] = options[:value]
  end

  options[:message] = error
  Lev::BetterActiveModelErrors.generate_message instance, field, :invalid, options
end

# Fail on missing translation in a spec.
I18n.exception_handler = lambda do |exception, locale, key, options|
  raise "Missing translation for #{key} in locale #{locale} with options #{options}"
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end


class ExternalAppForSpecsController < ActionController::Base
  skip_filter *_process_action_callbacks.map(&:filter)
  layout false

  def index
    render plain: 'This is a fake external application'
  end
end

# From: https://github.com/rspec/rspec-rails/issues/925#issuecomment-164094792
# See also: https://github.com/codeforamerica/ohana-api/blob/master/spec/api/cors_spec.rb
#
# Add support for testing `options` requests in RSpec.
# See: https://github.com/rspec/rspec-rails/issues/925
def options(*args)
  reset! unless integration_session
  integration_session.__send__(:process, :options, *args).tap do
    copy_session_variables!
  end
end
