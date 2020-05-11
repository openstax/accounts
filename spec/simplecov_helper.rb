require 'simplecov'
require 'codecov'
require 'parallel_tests'

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
  end

  # Merge coverage reports (and maybe send to codecov)
  SimpleCov::ResultMerger.merged_result.format!
end

# Start calculating code coverage
SimpleCov.start('rails') do
  add_filter '/spec'
  merge_timeout 3600
end
