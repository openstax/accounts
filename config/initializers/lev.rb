ActiveSupport.on_load(:active_job) do
  Lev.configure do |config|
    config.raise_fatal_errors = false
    config.job_class = ActiveJob::Base
  end
end
