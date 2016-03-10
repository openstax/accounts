require 'coveralls'
Coveralls.wear!('rails')

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/poltergeist'
require 'mail'

Mail.defaults { delivery_method :test }

# load seed data
load "#{Rails.root}/db/seeds.rb"

Capybara.javascript_driver = :poltergeist

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

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

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    # In RSpec 3, `any_instance` implementation blocks will be yielded the receiving
    # instance as the first block argument to allow the implementation block to use
    # the state of the receiver.
    # In RSpec 2.99, to maintain compatibility with RSpec 3 you need to either set
    # this config option to `false` OR set this to `true` and update your
    # `any_instance` implementation blocks to account for the first block argument
    # being the receiving instance.
    mocks.yield_receiver_to_any_instance_implementation_blocks = true
  end

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

# For rspec < 3.0 which doesn't have the output matcher
# See http://stackoverflow.com/questions/16507067/testing-stdout-output-in-rspec

require 'stringio'

def capture_output(&blk)
  old_stdout = $stdout
  old_stderr = $stderr
  $stdout = fake_stdout = StringIO.new
  $stderr = fake_stderr = StringIO.new
  blk.call
  [fake_stdout.string, fake_stderr.string]
ensure
  $stdout = old_stdout
  $stderr = old_stderr
end
