module Newflow
  class DeleteSalesforceLead

    lev_routine active_job_enqueue_options: { queue: :salesforce }

    protected #################

    # Called when a user abandons the educator flow. The SheerID webhook pushes a lead
    # at step 3, before the profile exists, so it carries an `incomplete_signup`
    # verification status -- nothing worth keeping, and leaving it behind puts a
    # phantom educator in the CS verification queue.
    def exec(user:)
      return unless user

      status.set_job_name(self.class.name)
      status.set_job_args(user: user.to_global_id.to_s)

      lead = find_lead(user)

      if lead.nil?
        user.update(salesforce_lead_id: nil) if user.salesforce_lead_id.present?
        SecurityLog.create!(user: user, event_type: :salesforce_lead_not_found_for_deletion)
        return
      end

      lead_id = lead.id.to_s

      begin
        lead.destroy
      rescue StandardError => e
        SecurityLog.create!(
          user: user,
          event_type: :salesforce_lead_delete_failed,
          event_data: { lead_id: lead_id, error: e.class.name, error_message: e.message }
        )
        Sentry.capture_message(
          "Failed to delete Salesforce lead #{lead_id} for user #{user.id}: #{e.class.name}: #{e.message}"
        )
        return
      end

      user.update(salesforce_lead_id: nil)
      SecurityLog.create!(
        user: user,
        event_type: :deleted_salesforce_lead,
        event_data: { lead_id: lead_id }
      )
      outputs.lead_id = lead_id
    end

    private ###################

    # Mirrors the lookup order in CreateOrUpdateSalesforceLead, which can find and
    # adopt a lead created by something other than this user's own signup.
    def find_lead(user)
      lead_by_id(user) ||
        OpenStax::Salesforce::Remote::Lead.find_by(accounts_uuid: user.uuid) ||
        lead_by_email(user)
    end

    def lead_by_id(user)
      return if user.salesforce_lead_id.blank?

      OpenStax::Salesforce::Remote::Lead.find(user.salesforce_lead_id)
    rescue StandardError
      nil
    end

    def lead_by_email(user)
      email = user.best_email_address_for_salesforce
      return if email.blank?

      OpenStax::Salesforce::Remote::Lead.find_by(email: email)
    end
  end
end
