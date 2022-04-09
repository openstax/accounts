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
# Values greater than 1 hour would require heartbeats
# for the lifecycle hook when terminating background job instances
Delayed::Worker.max_run_time = Rails.application.secrets[:background_worker_timeout]

# Default queue name if not specified in the job class
Delayed::Worker.default_queue_name = :default

# Default queue priorities
Delayed::Worker.queue_attributes = {
  educator_signup_queue: { priority: -10 },
  default:               { priority:   0 },
  salesforce:            { priority:   5 },
  mailers:               { priority:  10 }
}

# Allows us to use this gem in tests instead of setting the ActiveJob adapter to :inline
Delayed::Worker.delay_jobs = Rails.env.production? || (
                               Rails.env.development? && ActiveModel::Type::Boolean.new.cast(
                                 ENV.fetch('USE_REAL_BACKGROUND_JOBS', false)
                               )
                             )

module HandleFailedJobInstantly
  # Based on https://github.com/smartinez87/exception_notification/issues/195#issuecomment-31257207
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
    'ActiveJob::DeserializationError' => ALWAYS_FAIL,
    'OAuth2::Error'       => ->(exception) do
      status = exception.response.status
      400 <= status && status < 500
    end,
    'OpenURI::HTTPError'  => ->(exception) do
      status = exception.message.to_i
      400 <= status && status < 500
    end,
    'Restforce::ErrorCode' => ALWAYS_FAIL,
    'REQUEST_LIMIT_EXCEEDED' => ALWAYS_FAIL
  }

  def handle_failed_job(job, exception)
    Sentry.capture_exception(exception)
    fail_proc = INSTANT_FAILURE_PROCS[exception.class.name]
    job.fail! if fail_proc.present? && fail_proc.call(exception) ||
                 exception.try(:instantly_fail_if_in_background_job?)

                 super(job, exception)
  end
end

Delayed::Worker.prepend(HandleFailedJobInstantly)
