module Newflow
  class UpdateExistingSalesforceLead

    lev_routine active_job_enqueue_options: { queue: :salesforce }

    uses_routine CreateOrUpdateSalesforceLead

    protected #################

    # Used when a user changes role mid-signup. The lead is kept rather than deleted --
    # it is the only record of how often people pick the wrong role and who they are --
    # but one is never created here: a user who never reached SheerID has nothing in
    # Salesforce to correct, and students aren't leads in their own right.
    def exec(user:)
      return unless user

      status.set_job_name(self.class.name)
      status.set_job_args(user: user.to_global_id.to_s)

      lead = find_lead(user)

      if lead.nil?
        user.update(salesforce_lead_id: nil) if user.salesforce_lead_id.present?
        SecurityLog.create!(user: user, event_type: :no_salesforce_lead_to_update)
        return
      end

      # Hand the id to CreateOrUpdateSalesforceLead so it re-finds this same lead
      # rather than searching again and risking a different match.
      user.update(salesforce_lead_id: lead.id) unless user.salesforce_lead_id == lead.id

      run(CreateOrUpdateSalesforceLead, user: user)

      SecurityLog.create!(
        user: user,
        event_type: :updated_salesforce_lead_after_role_switch,
        event_data: { lead_id: lead.id.to_s, role_now: user.role }
      )

      outputs.lead_id = lead.id.to_s
    end

    private ###################

    # Mirrors the lookup order in CreateOrUpdateSalesforceLead, which can find and
    # adopt a lead this user's own signup didn't create.
    def find_lead(user)
      lead_by_id(user) ||
        OpenStax::Salesforce::Remote::Lead.find_by(accounts_uuid: user.uuid) ||
        lead_by_email(user)
    rescue StandardError => e
      SecurityLog.create!(
        user: user,
        event_type: :salesforce_lead_lookup_failed,
        event_data: { error: e.class.name, error_message: e.message }
      )
      Sentry.capture_message(
        "Salesforce lead lookup failed for user #{user.id}: #{e.class.name}: #{e.message}"
      )
      nil
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
