# A step must not abort the ones after it: OpenStax::RescueFrom.this re-raises in
# background (non-controller) context, which aborts the whole cron task on the first
# failure.
def cron_step(name)
  Rails.logger.info name
  yield
rescue StandardError => e
  Rails.logger.error "#{name} failed: #{e.class}: #{e.message}"
  Sentry.capture_exception(e, extra: { cron_step: name })
end
