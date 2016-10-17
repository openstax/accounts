require 'coveralls'
Coveralls.wear!('rails')

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/poltergeist'
require 'capybara/email/rspec'
require 'mail'

require 'shoulda/matchers'

Mail.defaults { delivery_method :test }

Capybara.javascript_driver = :poltergeist

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each{ |f| require f }

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

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:all) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:all, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:all, truncation: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:all) do
    DatabaseCleaner.start
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  # https://github.com/DatabaseCleaner/database_cleaner#rspec-with-capybara-example says:
  #   "It's also recommended to use append_after to ensure DatabaseCleaner.clean
  #    runs after the after-test cleanup capybara/rspec installs."
  config.append_after(:each) do
    DatabaseCleaner.clean
  end

  # Ideally we want nested transactions for before(:all)/after(:all)
  # and before(:each)/after(:each), but this is only possible in Rails >= 4.0
  # So for now we use truncation in after(:all)
  config.append_after(:all) do
    DatabaseCleaner.clean
  end

  # Some tests might change I18n.locale.
  config.after(:each) do |config|
    I18n.locale = :en
  end

  # For Capybara's poltergist tests ensure that request's locale is always
  # set to English.
  config.before(type: :feature, js: true) do |config|
    page.driver.add_header('Accept-Language', 'en')
  end
end

# Adds a convenience method to get interpret the body as JSON and convert to a hash;
# works for both request and controller specs
class ActionDispatch::TestResponse
  def body_as_hash
    @body_as_hash_cache ||= JSON.parse(body, symbolize_names: true)
  end
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
    "expected that response would have status '#{error_status}' but had #{actual.body_as_hash[:status]}"
  end
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
