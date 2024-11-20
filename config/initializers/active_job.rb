# Use delayed_job for background jobs
ActiveSupport.on_load(:active_job) { ActiveJob::Base.queue_adapter = :delayed_job }
