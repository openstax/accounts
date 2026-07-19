module Settings
  module Salesforce

    class << self

      def push_leads_enabled
        Settings::Db.store.push_salesforce_lead_enabled
      end

      def push_leads_enabled=(bool)
        Settings::Db.store.push_salesforce_lead_enabled = bool
      end

      def user_info_error_emails_enabled
        Settings::Db.store.user_info_error_emails_enabled
      end

      def user_info_error_emails_enabled=(bool)
        Settings::Db.store.user_info_error_emails_enabled=bool
      end

      def show_support_chat
        Settings::Db.store.show_support_chat
      end

      def show_support_chat=(bool)
        Settings::Db.store.show_support_chat = bool
      end

      def push_adoption_reports_enabled
        Settings::Db.store.push_adoption_reports_enabled
      end

      def push_adoption_reports_enabled=(bool)
        Settings::Db.store.push_adoption_reports_enabled = bool
      end

      def adoption_form_posting_url
        Settings::Db.store.adoption_form_posting_url
      end

      def adoption_form_posting_url=(url)
        Settings::Db.store.adoption_form_posting_url = url
      end

    end

  end
end
