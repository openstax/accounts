module Admin
  module SecurityLogsHelper
    EVENT_SUMMARY_LENGTH = 140

    def security_log_event_summary(event_data)
      return '(no data)' if event_data.blank?

      pairs = event_data.map { |key, value| "#{key}: #{security_log_summary_value(value)}" }
      truncate(pairs.join(', '), length: EVENT_SUMMARY_LENGTH)
    end

    def security_log_filter_path(prefix, value)
      admin_security_log_path(search: { query: %(#{prefix}:"#{security_log_escape_filter_value(value)}") })
    end

    def security_log_active_filters(query)
      return [] if query.blank?

      Admin::SearchSecurityLog.parse_filter_terms(query).map do |term|
        remaining_query = Admin::SearchSecurityLog.remove_filter_term(query, **term)

        {
          label: security_log_chip_label(term[:keyword], term[:value]),
          remove_path: admin_security_log_path(search: { query: remaining_query })
        }
      end
    end

    private

    def security_log_chip_label(keyword, value)
      case keyword
      when :id      then "ID ##{value}"
      when :user_id then "User ##{value}"
      when :user    then "User #{value}"
      when :app     then "App #{value}"
      when :ip      then "IP #{value}"
      when :type    then "Type #{value.humanize}"
      when :time    then "Time #{value}"
      else value
      end
    end

    # The query grammar has no escape for a literal double quote.
    def security_log_escape_filter_value(value)
      value.to_s.delete('"')
    end

    def security_log_summary_value(value)
      case value
      when Hash  then value.to_json
      when Array then value.join(', ')
      else value.to_s
      end
    end
  end
end
