require 'coveralls'
Coveralls.wear!('rails')

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/poltergeist'
require 'capybara/email/rspec'
require 'mail'

require 'shoulda/matchers'

Mail.defaults { delivery_method :test }

# load seed data
load "#{Rails.root}/db/seeds.rb"

Capybara.javascript_driver = :poltergeist

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# don't exit process until all ajax requests are complete
module WaitForAjax
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end
end

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  config.include WaitForAjax, type: :feature

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

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
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  # or set:
  #   config.infer_spec_type_from_file_location!
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

# monkey patching ActiveRecord::Base to use the same transaction for all threads
# http://rubydoc.info/github/jnicklas/capybara/master#Transactions_and_database_setup
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end

ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
