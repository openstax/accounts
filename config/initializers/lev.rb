Lev.configure do |config|
  config.raise_fatal_errors = false
  config.job_class = ActiveJob::Base
  config.create_status_proc = ->(*) { Jobba.create! }
  config.find_status_proc = ->(id) { Jobba.find!(id) }
end
