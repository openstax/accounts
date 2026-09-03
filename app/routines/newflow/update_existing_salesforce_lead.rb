module Newflow
  class UpdateExistingSalesforceLead

    lev_routine active_job_enqueue_options: { queue: :salesforce }

    uses_routine CreateOrUpdateSalesforceLead

    protected #################

    # Used when a user changes role mid-signup. The lead is kept rather than deleted --
    # it is the only record of how often people pick the wrong role and who they are --
    # but one is never created here: a user who never reached SheerID has nothing in
    # Salesforce to correct, and students aren't leads in their own right.
    #
    # Nothing Salesforce does may escape this routine. `Delayed::Worker.delay_jobs` is
    # only true in production, so everywhere else `perform_later` runs inline inside
    # the request and inside SwitchSignupRole's transaction -- an escaping error would
    # 500 the switch and roll back the role change, breaking the very fix the user
    # clicked. A missed update self-heals: UpdateUserLeadInfo reconciles lead ids and
    # statuses nightly.
    def exec(user:)
      return unless user

      status.set_job_name(self.class.name)
      status.set_job_args(user: user.to_global_id.to_s)

      lead = find_lead(user)

      # nil means Salesforce answered and has no lead; :unknown means it didn't answer,
      # and discarding a known association on that basis would lose data.
      return if lead == :unknown

      if lead.nil?
        user.update(salesforce_lead_id: nil) if user.salesforce_lead_id.present?
        SecurityLog.create!(user: user, event_type: :no_salesforce_lead_to_update)
        return
      end

      # Hand the id to CreateOrUpdateSalesforceLead so it re-finds this same lead
      # rather than searching again and risking a different match.
      user.update(salesforce_lead_id: lead.id) unless user.salesforce_lead_id == lead.id

      # It returns normally on a rejected write (it only logs salesforce_lead_save_failed),
      # so check before claiming success.
      return unless push_lead(user)

      SecurityLog.create!(
        user: user,
        event_type: :updated_salesforce_lead_after_role_switch,
        event_data: { lead_id: lead.id.to_s, role_now: user.role }
      )

      outputs.lead_id = lead.id.to_s
    end

    private ###################

    def push_lead(user)
      run(CreateOrUpdateSalesforceLead, user: user).outputs.lead_saved
    rescue StandardError => e
      report(user, 'lead update failed', e)
      false
    end

    # Mirrors the lookup order in CreateOrUpdateSalesforceLead, which can find and
    # adopt a lead this user's own signup didn't create.
    def find_lead(user)
      lead_by_id(user) ||
        OpenStax::Salesforce::Remote::Lead.find_by(accounts_uuid: user.uuid) ||
        lead_by_email(user)
    rescue StandardError => e
      report(user, 'lead lookup failed', e)
      :unknown
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

    # Sentry rather than SecurityLog: this runs inside the caller's transaction, which
    # may roll back, and an unreachable Salesforce isn't an account-audit event.
    def report(user, what, error)
      Sentry.capture_message(
        "Salesforce #{what} for user #{user.id}: #{error.class.name}: #{error.message}"
      )
    end
  end
end
