module Settings
  module Salesforce
    class << self
      def push_leads_enabled
        Settings::Db.store.push_salesforce_lead_enabled
      end

      def push_leads_enabled=(bool)
        Settings::Db.store.push_salesforce_lead_enabled = bool
      end

      def push_students_enabled
        Settings::Db.store.push_salesforce_students_enabled
      end

      def push_students_enabled=(bool)
        Settings::Db.store.push_salesforce_students_enabled = bool
      end

      def push_contact_logins_enabled
        Settings::Db.store.push_salesforce_contact_logins_enabled
      end

      def push_contact_logins_enabled=(bool)
        Settings::Db.store.push_salesforce_contact_logins_enabled = bool
      end

      def push_last_seen_enabled
        Settings::Db.store.push_salesforce_last_seen_enabled
      end

      def push_last_seen_enabled=(bool)
        Settings::Db.store.push_salesforce_last_seen_enabled = bool
      end

      def user_info_error_emails_enabled
        Settings::Db.store.user_info_error_emails_enabled
      end

      def user_info_error_emails_enabled=(bool)
        Settings::Db.store.user_info_error_emails_enabled = bool
      end

      def show_support_chat
        Settings::Db.store.show_support_chat
      end

      def show_support_chat=(bool)
        Settings::Db.store.show_support_chat = bool
      end

      def contacts_synced_through
        value = Settings::Db.store.contacts_synced_through
        Time.iso8601(value) if value.present?
      end

      def contacts_synced_through=(time)
        Settings::Db.store.contacts_synced_through = time&.utc&.iso8601
      end
    end
  end
end
