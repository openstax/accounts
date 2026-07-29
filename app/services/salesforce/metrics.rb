module Salesforce
  # Per-run counter bag for the Salesforce sync routines.
  #
  # Routines instantiate one Metrics, increment counters during the run, and
  # call #emit at the end. emit writes a Sentry check-in (when a slug is
  # configured) plus a single JSON log line tagged with the run name. #alert!
  # produces a tagged Sentry message for threshold-based alerts so existing
  # tag-based alert rules can subscribe to the `salesforce-alert` tag.
  class Metrics
    attr_reader :counters, :run, :slug, :started_at

    def initialize(run:, slug: nil)
      @run = run
      @slug = slug
      @counters = {}
      @started_at = Time.current
      @check_in_id = nil
    end

    # Mark a Sentry check-in as in_progress so the eventual #emit can close it.
    def start!
      return unless slug
      @check_in_id = Sentry.capture_check_in(slug, :in_progress)
    end

    # Increment a counter. With no labels, stores an integer.
    # With keyword labels, stores a hash with :total plus a per-label tally.
    def increment(key, by: 1, **labels)
      if labels.empty?
        current = @counters[key]
        @counters[key] = (current.is_a?(Integer) ? current : 0) + by
      else
        existing = @counters[key].is_a?(Hash) ? @counters[key] : { total: 0 }
        existing[:total] = (existing[:total] || 0) + by
        labels.each_value do |label_value|
          existing[label_value] = (existing[label_value] || 0) + by
        end
        @counters[key] = existing
      end
    end

    def emit(status: :ok, extra: {})
      payload = {
        run: run,
        status: status,
        duration_s: (Time.current - started_at).to_i,
        counters: counters,
        **extra
      }
      Rails.logger.tagged('salesforce', run) { Rails.logger.info(payload.to_json) }
      Sentry.capture_check_in(slug, status, check_in_id: @check_in_id) if slug
      payload
    end

    def alert!(name, value:, threshold:)
      Sentry.capture_message(
        "Salesforce alert: #{name} (value=#{value}, threshold=#{threshold})",
        tags: { 'salesforce-alert' => name.to_s },
        extra: { value: value, threshold: threshold, run: run }
      )
    end
  end
end
