module Admin
  module SecurityLogsHelper
    EVENT_SUMMARY_LENGTH = 140

    def security_log_event_summary(event_data)
      return '(no data)' if event_data.blank?

      pairs = event_data.map { |key, value| "#{key}: #{security_log_summary_value(value)}" }
      truncate(pairs.join(', '), length: EVENT_SUMMARY_LENGTH)
    end

    def security_log_filter_path(prefix, value)
      admin_security_log_path(search: { query: %(#{prefix}:"#{value}") })
    end

    private

    def security_log_summary_value(value)
      case value
      when Hash  then value.to_json
      when Array then value.join(', ')
      else value.to_s
      end
    end
  end
end
