# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
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
    EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new
  end

  config.before(:all) do
    load('db/seeds.rb')
  end

  config.before(:each) do
    # Get rid of possibly-shared config setting cache values between test and dev or any leftover
    # cached values from other test runs. This is 15 seconds faster than `Rails.cache.clear`
    Rails.cache.delete_matched("rails_settings_cached/*")
  end

  # Some tests might change I18n.locale.
  config.before(:each) do |config|
    I18n.locale = :en # rubocop:disable Rails/I18nLocaleAssignment
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

  # Ability to test job results in tests by actually processing the jobs
  config.before :example, perform_enqueued: true do
    @old_perform_enqueued_jobs = ActiveJob::Base.queue_adapter.perform_enqueued_jobs
    @old_perform_enqueued_at_jobs = ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
  end

  config.after :example, perform_enqueued: true do
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs  = @old_perform_enqueued_jobs
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = @old_perform_enqueued_at_jobs
  end

  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  #config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = '.rspec_last_failures'

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  #config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  #config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  #config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true

    expectations.syntax = :expect
  end

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec do |mocks|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
    mocks.syntax = :expect

    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end
end

"""
  Rspec matcher definitions
"""
RSpec::Matchers.define_negated_matcher :not_change, :change

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
    "expected that response would have error '#{error_code.to_s}' but had #{actual.body_as_hash[:errors].pluck(:code)}"
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

RSpec::Matchers.define :have_error do |field, message|
# Check a model instance for error presence. For example
#
#   model = Model.create(id: already_taken_value, name: 'Name')
#   expect(model).to have_error(:id, :taken)
#   expect(model).not_to have_error(:name, :blank)

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

"""
  Custom helper methods
"""
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
def error_msg(model, *args)
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
      group        = model.paramify_classes.keys[0]
    end

    model = model.paramify_classes[group]

    if model.nil?
      raise "#{model_or_name} is a Lev handler but is not paramified"
    end
  else
    field, error, options = args
  end
  options       ||= {}

  instance = model.new
  if options.has_key? :value
    instance[field] = options[:value]
  end

  options[:message] = error
  Lev::BetterActiveModelErrors.generate_message instance, field, :invalid, options
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

def in_travis?
  ENV['CI']
end

def in_docker?
  ENV['HUB_URL'].present?
end
