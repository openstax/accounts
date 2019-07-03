# Defaults:
# Delayed::Worker.destroy_failed_jobs = true
# Delayed::Worker.sleep_delay = 5
# Delayed::Worker.max_attempts = 25
# Delayed::Worker.max_run_time = 4.hours
# Delayed::Worker.read_ahead = 5
# Delayed::Worker.default_queue_name = nil
# Delayed::Worker.delay_jobs = true
# Delayed::Worker.raise_signal_exceptions = false
# Delayed::Worker.logger = Rails.logger

# Keep failed jobs for later inspection
Delayed::Worker.destroy_failed_jobs = false

# Should be longer than the longest background job (that actually uses this gem)
Delayed::Worker.max_run_time = Rails.application.secrets[:background_worker_timeout]

# Allows us to use this gem in tests instead of setting the ActiveJob adapter to :inline
Delayed::Worker.delay_jobs = Rails.env.production? ||
                             ( Rails.env.development? &&
                               ActiveModel::Type::Boolean.new.cast(
                                 ENV['USE_REAL_BACKGROUND_JOBS'] || 'false'
                               )
                             )

# https://github.com/smartinez87/exception_notification/issues/195#issuecomment-31257207
Delayed::Worker.class_exec do
  ALWAYS_FAIL = ->(exception) { true }

  INSTANT_FAILURE_PROCS = {
    'ActiveRecord::RecordInvalid' => ALWAYS_FAIL,
    'ActiveRecord::RecordNotFound' => ALWAYS_FAIL,
    'Addressable::URI::InvalidURIError' => ALWAYS_FAIL,
    'ArgumentError' => ALWAYS_FAIL,
    'JSON::ParserError' => ALWAYS_FAIL,
    'NameError' => ALWAYS_FAIL,
    'NoMethodError' => ALWAYS_FAIL,
    'NotYetImplemented' => ALWAYS_FAIL,
    # http://stackoverflow.com/a/31928089
    'ActiveJob::DeserializationError' => ->(exception) do
      exception.original_exception.is_a? ActiveRecord::RecordNotFound
    end,
    'OAuth2::Error'       => ->(exception) do
      status = exception.response.status
      400 <= status && status < 500
    end,
    'OpenURI::HTTPError'  => ->(exception) do
      status = exception.message.to_i
      400 <= status && status < 500
    end
  }

  def handle_failed_job_with_instant_failures(job, exception)
    fail_proc = INSTANT_FAILURE_PROCS[exception.class.name]
    job.fail! if fail_proc.present? && fail_proc.call(exception)

    handle_failed_job_without_instant_failures(job, exception)
  end

  alias_method_chain :handle_failed_job, :instant_failures
end
