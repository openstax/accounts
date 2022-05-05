require 'rails'
require 'active_model'
require 'dotenv/rails-now'

require_relative 'dev_url_options'

APP_DIR = File.expand_path('..', __dir__)
directory APP_DIR

tag 'OpenStax Accounts Puma'

NUM_WORKERS = ENV.fetch('WEB_CONCURRENCY') { Etc.nprocessors }.to_i

worker_timeout ENV.fetch('WORKER_TIMEOUT', 60).to_i

stdout_redirect(
  ENV.fetch('STDOUT_LOGFILE', "#{APP_DIR}/log/puma.stdout.log"),
  ENV.fetch('STDERR_LOGFILE', "#{APP_DIR}/log/puma.stderr.log"),
  true
) if ActiveModel::Type::Boolean.new.cast(ENV.fetch('REDIRECT_STDOUT', false))

before_fork do
  require 'puma_worker_killer'

  PumaWorkerKiller.config do |config|
    # Restart workers when they start consuming too much of the RAM
    config.ram = ENV.fetch('MAX_MEMORY') do
      ENV.fetch('MAX_WORKER_MEMORY', 1024).to_i * NUM_WORKERS
    end.to_i

    config.frequency = 10

    config.percent_usage = 0.75

    config.rolling_restart_frequency = false

    config.reaper_status_logs = false
  end

  PumaWorkerKiller.start
end

# https://github.com/rails/rails/blob/master/railties/lib/rails/generators/rails/app/templates/config/puma.rb.tt

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads = ENV.fetch('RAILS_MAX_THREADS', 5).to_i
threads ENV.fetch('RAILS_MIN_THREADS', max_threads).to_i, max_threads

if ENV.fetch('SOCKET')
  # Specifies the `socket` to which Puma will bind to receive requests.
  bind ENV.fetch('SOCKET')
else
  # Specifies the `port` that Puma will listen on to receive requests; default is DEV_PORT (2999).
  port ENV.fetch('PORT', DEV_PORT)
end

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch('RAILS_ENV', 'development')

# Specifies the `pidfile` that Puma will use.
#
pidfile ENV.fetch('PIDFILE', 'tmp/pids/puma.pid')

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers NUM_WORKERS

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app! if ActiveModel::Type::Boolean.new.cast(ENV.fetch('PRELOAD_APP', false))

# Allow puma to be restarted by `rails restart` command.
#
plugin :tmp_restart

# Call GC.start and GC.compact before forking to try to reduce worker memory usage
nakayoshi_fork

# Adds a small delay before accepting requests if the worker (process) has threads already
# processing other requests, to try to get idle workers to accept the request
wait_for_less_busy_worker ENV.fetch('WAIT_FOR_LESS_BUSY_WORKERS', '0.005').to_f
