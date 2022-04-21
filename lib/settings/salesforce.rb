module Settings
  module Salesforce

    class << self

      def push_salesforce_lead_enabled
        Settings::Db.store.push_salesforce_lead_enabled
      end

      def push_salesforce_lead_enabled=(bool)
        Settings::Db.store.push_salesforce_lead_enabled = bool
      end

      def user_info_error_emails_enabled
        Settings::Db.store.user_info_error_emails_enabled
      end

      def user_info_error_emails_enabled=(bool)
        Settings::Db.store.user_info_error_emails_enabled=bool
      end

      def sync_accounts_to_salesforce_enabled
        Settings::Db.store.sync_accounts_to_salesforce_enabled
      end

      def sync_accounts_to_salesforce_enabled=(bool)
        Settings::Db.store.sync_accounts_to_salesforce_enabled = bool
      end

      def sync_contacts_to_salesforce_enabled
        Settings::Db.store.sync_contacts_to_salesforce_enabled
      end

      def sync_contacts_to_salesforce_enabled=(bool)
        Settings::Db.store.sync_contacts_to_salesforce_enabled = bool
      end

    end

  end
end
