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

      # SyncContacts cursor — UTC time of the last successful run.
      def contacts_synced_through
        v = Settings::Db.store.salesforce_contacts_synced_through
        v.present? ? Time.iso8601(v) : nil
      end

      def contacts_synced_through=(time)
        Settings::Db.store.salesforce_contacts_synced_through = time&.utc&.iso8601
      end

      def contacts_lookback_overlap_hours
        Settings::Db.store.salesforce_contacts_lookback_overlap_hours
      end

      # Reconcile budget — soft cap on Salesforce queries per run.
      def reconcile_max_queries
        Settings::Db.store.salesforce_reconcile_max_queries
      end

      def reconcile_pass_cursors
        Settings::Db.store.salesforce_reconcile_pass_cursors || {}
      end

      def reconcile_pass_cursors=(hash)
        Settings::Db.store.salesforce_reconcile_pass_cursors = hash
      end

      # Threshold knobs for the per-run alert checks.
      def alert_lead_save_failure_rate_pct
        Settings::Db.store.salesforce_alert_lead_save_failure_rate_pct
      end

      def alert_contact_id_conflict_count
        Settings::Db.store.salesforce_alert_contact_id_conflict_count
      end

      def alert_contact_id_swap_rate_pct
        Settings::Db.store.salesforce_alert_contact_id_swap_rate_pct
      end

      def alert_unknown_uuid_count
        Settings::Db.store.salesforce_alert_unknown_uuid_count
      end

      def alert_drift_open_total
        Settings::Db.store.salesforce_alert_drift_open_total
      end

      def alert_cron_drift_hours
        Settings::Db.store.salesforce_alert_cron_drift_hours
      end

      def sf_admin_notify_enabled
        Settings::Db.store.salesforce_sf_admin_notify_enabled
      end

    end

  end
end
