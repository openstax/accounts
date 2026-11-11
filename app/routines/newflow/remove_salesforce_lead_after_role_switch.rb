module Newflow
  class RemoveSalesforceLeadAfterRoleSwitch

    lev_routine active_job_enqueue_options: { queue: :salesforce }

    uses_routine CreateOrUpdateSalesforceLead

    SALESFORCE_ID = /\A[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?\z/
    private_constant :SALESFORCE_ID

    protected #################

    # Used when an educator switches to student mid-signup. Students aren't leads, so
    # the lead this signup created is deleted; the user_switched_signup_role security
    # log already records the switch. A lead that existed before the signup (adopted by
    # uuid or email) or has converted carries history this signup didn't write, so it
    # is relabelled Student instead. A lead is never created here.
    #
    # In development and test, `perform_later` runs inline inside SwitchSignupRole's
    # transaction, so Salesforce failures must be swallowed there or the role change
    # would roll back. In a real delayed job, the same failures must raise so the
    # worker retries and we don't silently leave the lead on the educator path.
    def exec(user:)
      return unless user

      status.set_job_name(self.class.name)
      status.set_job_args(user: user.to_global_id.to_s)

      lead = find_lead(user)

      # nil means Salesforce answered and has no lead; :unknown means it didn't answer,
      # and discarding a known association on that basis would lose data.
      raise_retryable_failure!("lead lookup failed", user) if lead == :unknown && retry_on_failure?
      return if lead == :unknown

      if lead.nil?
        user.update(salesforce_lead_id: nil) if user.salesforce_lead_id.present?
        SecurityLog.create!(user: user, event_type: :no_salesforce_lead_to_update)
        return
      end

      created_by_signup = created_by_this_signup?(lead, user)
      if created_by_signup == :unknown
        raise_retryable_failure!('lead created date lookup failed', user) if retry_on_failure?
        return
      end

      created_by_signup ? delete_lead(user, lead) : relabel_lead(user, lead)
    end

    private ###################

    def delete_lead(user, lead)
      lead.destroy
    rescue StandardError => e
      report(user, 'lead delete failed', e)
      raise_retryable_failure!('lead delete failed', user) if retry_on_failure?
    else
      user.update(salesforce_lead_id: nil)
      SecurityLog.create!(
        user: user,
        event_type: :deleted_salesforce_lead_after_role_switch,
        event_data: { lead_id: lead.id.to_s }
      )
    end

    def relabel_lead(user, lead)
      # Hand the id to CreateOrUpdateSalesforceLead so it re-finds this same lead
      # rather than searching again and risking a different match.
      user.update(salesforce_lead_id: lead.id) unless user.salesforce_lead_id == lead.id

      # It returns normally on a rejected write (it only logs salesforce_lead_save_failed),
      # so check before claiming success.
      lead_pushed = push_lead(user)
      raise_retryable_failure!("lead update failed", user) if !lead_pushed && retry_on_failure?
      return unless lead_pushed

      SecurityLog.create!(
        user: user,
        event_type: :updated_salesforce_lead_after_role_switch,
        event_data: { lead_id: lead.id.to_s, role_now: user.role }
      )

      outputs.lead_id = lead.id.to_s
    end

    # A converted lead is followed to its Contact, which reports contact_saved and
    # leaves lead_saved false.
    def push_lead(user)
      pushed = run(CreateOrUpdateSalesforceLead, user: user).outputs
      pushed.lead_saved || pushed.contact_saved
    rescue StandardError => e
      report(user, 'lead update failed', e)
      false
    end

    # LeadSource can't tell who made a lead: CreateOrUpdateSalesforceLead stamps
    # Account Creation on every lead it touches, adopted ones included. A lead created
    # after this account was is one this signup made. The gem's Lead doesn't map
    # CreatedDate, so it is read directly.
    def created_by_this_signup?(lead, user)
      return false if lead.is_converted || !lead.id.to_s.match?(SALESFORCE_ID)

      soql = "SELECT CreatedDate FROM Lead WHERE Id = '#{lead.id}'"
      record = ActiveForce.sfdc_client.query(soql).first
      record.present? && Time.zone.parse(record['CreatedDate']) >= user.created_at
    rescue StandardError => e
      report(user, 'lead created date lookup failed', e)
      :unknown
    end

    # Mirrors the lookup order in CreateOrUpdateSalesforceLead, which can find and
    # adopt a lead this user's own signup didn't create.
    def find_lead(user)
      lead_by_id(user) ||
        OpenStax::Salesforce::Remote::Lead.find_by(accounts_uuid: user.uuid) ||
        lead_by_email(user) ||
        (:unknown if @id_lookup_failed)
    rescue StandardError => e
      report(user, 'lead lookup failed', e)
      :unknown
    end

    # ActiveForce's `find` is a SOQL query, so a lead that no longer exists comes
    # back nil rather than raising -- reaching the rescue means the lookup failed,
    # not that the lead is gone. Keep searching by uuid and email, since a stored id
    # can also be stale garbage that those will get past, but remember the failure:
    # if nothing turns up, the caller must not read that as "Salesforce has no lead"
    # and clear a real association.
    def lead_by_id(user)
      return if user.salesforce_lead_id.blank?

      OpenStax::Salesforce::Remote::Lead.find(user.salesforce_lead_id)
    rescue StandardError => e
      @id_lookup_failed = true
      report(user, 'lead lookup by stored id failed', e)
      nil
    end

    def lead_by_email(user)
      email = user.best_email_address_for_salesforce
      return if email.blank?

      OpenStax::Salesforce::Remote::Lead.find_by(email: email)
    end

    def retry_on_failure?
      Delayed::Worker.delay_jobs
    end

    def raise_retryable_failure!(what, user)
      raise StandardError, "Salesforce #{what} for user #{user.id}"
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
