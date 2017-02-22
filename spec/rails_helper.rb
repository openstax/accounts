require 'simplecov'
require 'codecov'
require 'parallel_tests'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::Codecov
]) if ENV['CI'] == 'true'

SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!

require 'openstax/salesforce/spec_helpers'
include OpenStax::Salesforce::SpecHelpers

require 'shoulda/matchers'

require 'capybara'
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
window_size = [1920, 6000]

Capybara.asset_host = 'http://localhost:2999'

require 'capybara/email/rspec'

do_screenshots = EnvUtilities.load_boolean(name: 'SSHOT', default: false)

if do_screenshots
  require 'capybara-screenshot/rspec'
  Capybara::Screenshot.autosave_on_failure = false
  Capybara::Screenshot.append_timestamp = false
  window_size = [1000, 6000] # narrower images

  def screenshots_dir
    $screenshots_dir ||= Rails.root.join "tmp/capybara/screenshots_#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}"
  end

  def screenshot!(suffix: nil)
    include_html_screenshots = false

    original_save_path = Capybara.save_path
    begin
      Capybara.save_path = screenshots_dir
      saver = Capybara::Screenshot::Saver.new(
        Capybara, Capybara.page, include_html_screenshots, screenshot_base(suffix)
      )

      wait_for_ajax
      wait_for_animations

      if saver.save
        {:html => saver.html_path, :image => saver.screenshot_path}
      end
    ensure
      Capybara.save_path = original_save_path
    end
  end

  def capture_email!(address: nil, suffix: nil)
    open_email(address) if address.present?

    # Used to just call built-in `save_page`, but switched to below to add headers
    # current_email.save_page("#{screenshots_dir}/#{screenshot_base(suffix)}.html")

    path = "#{screenshots_dir}/#{screenshot_base(suffix)}.html"
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path,'w') do |f|
      f.write("Subject: #{current_email.subject}<br/>")
      f.write("To: #{current_email.to.join(', ')}<br/>")
      f.write("From: #{current_email.from.join(', ')}<br/>")
      f.write("--------------------<br/><br/>")
      f.write(current_email.body)
    end
  end

  def screenshot_base(suffix=nil)
    @screenshot_prefix_usage_counts ||= {}
    prefix = "#{self.class.description}_#{RSpec.current_example.description}".gsub(/\W+/,'_')
    @screenshot_prefix_usage_counts[prefix] ||= 0
    next_available_index = (@screenshot_prefix_usage_counts[prefix] += 1)
    "#{prefix}_#{next_available_index}#{'_' + suffix if suffix.present?}".gsub(/\W+/,'_')
  end
else
  def screenshot!(*args); end
  def capture_email!(*args); end
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    :window_size => window_size
  })
end

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

  config.append_after(:all) do
    DatabaseCleaner.clean
  end

  # Some tests might change I18n.locale.
  config.before(:each) do |config|
    I18n.locale = :en
  end

  # For Capybara's poltergist tests ensure that request's locale is always set to English.
  config.before(type: :feature, js: true) do |config|
    # page.driver.header 'Accept-Language', 'en'
    page.driver.add_header('Accept-Language', 'en')
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
