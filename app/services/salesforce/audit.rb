module Salesforce
  module Audit
    EVENT_PREFIX = 'salesforce_'.freeze

    def self.record(user, event_name, **details)
      full = "#{EVENT_PREFIX}#{event_name}"
      unless SecurityLog.event_types.key?(full)
        raise ArgumentError, "Unknown Salesforce audit event: #{full.inspect}. Add it to SecurityLog#event_type."
      end
      SecurityLog.create!(user: user, event_type: full, event_data: details)
    end
  end
end
