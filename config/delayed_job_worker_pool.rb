require 'etc'
require 'sd_notify'
require 'scout_apm'

# Notify systemd that we are the main process
SdNotify.mainpid Process.pid

preload_app

worker_group do |group|
  group.workers = Integer(ENV['NUM_WORKERS'] || Etc.nprocessors)
  group.queues = (ENV['QUEUES'] || ENV['QUEUE'] || '').split(',')
end

# Monkeypatches
DelayedJobWorkerPool::WorkerPool.class_exec do
  # Notify systemd and start a watchdog thread after all workers have been booted
  def run
    log("Starting master #{Process.pid}")

    install_signal_handlers

    if preload_app?
      load_app
      invoke_callback(:after_preload_app)
    end

    log_uninheritable_threads

    fork_workers

    if SdNotify.watchdog?
      watchdog_thread_sleep_interval = Integer(ENV['WATCHDOG_USEC']) / 2000000
      log "Starting watchdog thread with sleep interval #{watchdog_thread_sleep_interval} seconds"

      # Start the watchdog thread with high priority
      Thread.new do
        loop do
          sleep watchdog_thread_sleep_interval

          SdNotify.watchdog
        end
      end.priority = Integer(ENV['WATCHDOG_PRIORITY'] || 100)
    end

    # Notify systemd of our PID and that we have finished booting up
    log 'Notifying systemd that we are ready'
    SdNotify.ready

    monitor_workers

    return
  ensure
    master_alive_write_pipe.close if master_alive_write_pipe
    master_alive_read_pipe.close if master_alive_read_pipe
  end

  private

  # Don't complain about fork-safe threads (Rails 6.1)
  def log_uninheritable_threads
    Thread.list.reject { |t| t.thread_variable_get(:fork_safe) }.each do |t|
      next if t == Thread.current

      if t.respond_to?(:backtrace)
        log("WARNING: Thread will not be inherited by workers: #{t.inspect} - " \
            "#{t.backtrace ? t.backtrace.first : ''}")
      else
        log("WARNING: Thread will not be inherited by workers: #{t.inspect}")
      end
    end
  end

  # Notify systemd when delayed_job_worker_pool is stopping
  def shutdown(signal)
    log 'Notifying systemd that we are shutting down'
    SdNotify.stopping
    log("Shutting down master #{Process.pid} with signal #{signal}")
    self.shutting_down = true
    registry.worker_pids.each do |child_pid|
      group = registry.group(child_pid)
      log("Telling worker #{child_pid} from group #{group} to shutdown with signal #{signal}")
      Process.kill(signal, child_pid)
    end
  end
end

# Make sure scout_apm doesn't start until we fork
::ScoutApm::BackgroundJobIntegrations::DelayedJob.class_exec do
  def forking?
    true
  end
end
