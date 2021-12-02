Delayed::Heartbeat.configure do |configuration|
  configuration.heartbeat_interval_seconds = 30
  configuration.heartbeat_timeout_seconds = 60
  configuration.on_worker_termination = ->(worker_model, exception) do
    Raven.capture_exception(
      exception,
      logger: 'delayed_job_heartbeat_plugin',
      extra: { delayed_worker: worker_model.attributes }
    )
  end
  configuration.worker_version = Rails.application.secrets.release_version
end

# Monkeypatch to use exit! instead of exit
# Either openstax_rescue_from or delayed_job rescues SystemExit and prevents termination with exit
Delayed::Heartbeat::WorkerHeartbeat.class_exec do
  def run_heartbeat_loop
    loop do
      break if sleep_interruptibly(heartbeat_interval)
      update_heartbeat
      # Return the connection back to the pool since we won't be needing
      # it again for a while.
      Delayed::Backend::ActiveRecord::Job.clear_active_connections!
    end
  rescue => e
    # We don't want the worker to continue running if the heartbeat can't be written.
    # Don't use Thread.abort_on_exception because that will give Delayed::Job a chance
    # to mark the job as failed which will unlock it even though the clock
    # process has likely already unlocked it and another worker may have picked it up.
    Delayed::Heartbeat.configuration.on_worker_termination.call(@worker_model, e)
    exit!(false)
  ensure
    @stop_reader.close
    @worker_model.delete
    # Note: The built-in Delayed::Plugins::ClearLocks will unlock the jobs for us
    Delayed::Backend::ActiveRecord::Job.clear_active_connections!
  end
end
