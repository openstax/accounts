module Settings
  module Salesforce

    class << self

      def push_leads_enabled
        Settings::Db.store.push_salesforce_lead_enabled
      end

      def push_leads_enabled=(bool)
        Settings::Db.store.push_salesforce_lead_enabled = bool
      end

    end

  end
end
