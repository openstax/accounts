# Use delayed_job for background jobs
ActiveJob::Base.queue_adapter = :delayed_job
