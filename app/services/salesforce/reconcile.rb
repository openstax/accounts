module Salesforce
  # Nightly two-way drift detection + Accounts-side self-heal.
  #
  # Pass 1: anchor on users with stored salesforce_contact_id; verify the
  #         SF Contact is alive and owns this user. Heal merges/deletes/
  #         disowned records; open drift findings for everything we can't
  #         resolve on the Accounts side.
  # Pass 2: anchor on users with stored salesforce_lead_id (no contact).
  #         Attach a Contact when the Lead has been converted; clear and
  #         re-resolve when the Lead is missing or disowned.
  # Pass 3: discover missing links for profile-complete instructors with
  #         no stored ids, by looking them up in SF by accounts_uuid.
  # SF-orphan sweep: find SF Leads/Contacts whose accounts_uuid we don't
  #         recognize (last 90 days of LastModifiedDate); open findings.
  # Finalize: close findings not refreshed during this run; prune ancient
  #         resolved findings; fire the drift_findings_total_open alert.
  #
  # Self-heal writes are gated by Settings::FeatureFlags
  # .salesforce_reconcile_self_heal (default false on first deploy).
  class Reconcile
    SLUG       = 'reconcile-salesforce'.freeze
    BATCH_SIZE = 500
    SWEEP_LOOKBACK = 90.days

    def self.call
      new.call
    end

    def initialize
      @metrics = Metrics.new(run: 'reconcile', slug: SLUG)
      @self_heal = Settings::FeatureFlags.salesforce_reconcile_self_heal
      @queries = 0
      @max_queries = Settings::Salesforce.reconcile_max_queries
    end

    def call
      @metrics.start!
      log "Reconcile starting (self_heal=#{@self_heal})"
      run_pass_1
      run_pass_2
      run_pass_3
      sweep_sf_orphans
      finalize_findings
      @metrics.emit(status: :ok)
    rescue StandardError => e
      Sentry.capture_exception(e)
      @metrics.emit(status: :error, extra: { error: e.class.name })
      raise
    end

    # ----- Pass 1: contact-anchored ----- #

    def run_pass_1
      User.where.not(salesforce_contact_id: nil).find_in_batches(batch_size: BATCH_SIZE) do |users|
        break if budget_exceeded?
        contact_ids = users.map(&:salesforce_contact_id).uniq
        contacts = fetch_contacts_by_id(contact_ids)
        users.each { |u| reconcile_user_by_stored_contact(u, contacts[u.salesforce_contact_id]) }
        @metrics.increment(:users_pass_1, by: users.size)
      end
    end

    def fetch_contacts_by_id(ids)
      return {} if ids.empty?
      @queries += 1
      Salesforce::Records::Contact
        .select(:id, :accounts_uuid, :master_record_id, :is_deleted)
        .where(id: ids).index_by(&:id)
    end

    def reconcile_user_by_stored_contact(user, sf_contact)
      if sf_contact.nil?
        finding(user, 'sf_contact_uuid_mismatch', 'Contact', user.salesforce_contact_id, details: { reason: 'missing_in_sf' })
        heal_clear_contact_id(user)
        return
      end

      if sf_contact.is_deleted
        finding(user, 'sf_contact_uuid_mismatch', 'Contact', sf_contact.id, details: { reason: 'is_deleted' })
        heal_clear_contact_id(user)
        return
      end

      if sf_contact.master_record_id.present?
        master = safe_find(Salesforce::Records::Contact, sf_contact.master_record_id)
        if master && Verify.contact_owns_user?(master, user)
          heal_swap_contact_id(user, master.id, reason: :merged)
        else
          finding(user, 'sf_contact_uuid_mismatch', 'Contact', sf_contact.id, details: { reason: 'merged_no_owner_match' })
          heal_clear_contact_id(user)
        end
        return
      end

      if sf_contact.accounts_uuid.blank?
        finding(user, 'sf_contact_missing_uuid', 'Contact', sf_contact.id)
        return  # SF-side problem; do not mutate Accounts
      end

      if sf_contact.accounts_uuid != user.uuid
        finding(user, 'sf_contact_uuid_mismatch', 'Contact', sf_contact.id, details: { uuid_in_sf: sf_contact.accounts_uuid })
        heal_reattach_via_lookup(user)
        return
      end

      Audit.record(user, :reconcile_user_ok, contact_id: sf_contact.id)
      close_findings(user, category: 'sf_contact_uuid_mismatch')
    end

    def heal_clear_contact_id(user)
      return unless @self_heal
      prior = user.salesforce_contact_id
      user.update!(salesforce_contact_id: nil)
      Audit.record(user, :reconcile_contact_id_cleared, prior: prior)
      @metrics.increment(:contact_clears)
      heal_reattach_via_lookup(user)
    end

    def heal_swap_contact_id(user, new_id, reason:)
      return unless @self_heal
      from = user.salesforce_contact_id
      user.update!(salesforce_contact_id: new_id)
      Audit.record(user, :reconcile_followed_merge, from: from, to: new_id, reason: reason)
      @metrics.increment(:contact_swaps_by_reconcile, reason: reason)
    end

    def heal_reattach_via_lookup(user)
      return unless @self_heal
      contact = Lookup.contact_for(user)
      if contact
        user.update!(salesforce_contact_id: contact.id)
        Audit.record(user, :link_restored_by_reconcile, contact_id: contact.id)
        @metrics.increment(:links_restored)
      else
        prior = user.salesforce_contact_id_was || user.salesforce_contact_id
        Audit.record(user, :contact_id_orphaned, prior_contact_id: prior)
        @metrics.increment(:contacts_orphaned)
      end
    end

    # ----- Pass 2: lead-anchored ----- #

    def run_pass_2
      User.where(salesforce_contact_id: nil).where.not(salesforce_lead_id: nil)
          .find_in_batches(batch_size: BATCH_SIZE) do |users|
        break if budget_exceeded?
        lead_ids = users.map(&:salesforce_lead_id).uniq
        leads = fetch_leads_by_id(lead_ids)
        users.each { |u| reconcile_user_by_stored_lead(u, leads[u.salesforce_lead_id]) }
        @metrics.increment(:users_pass_2, by: users.size)
      end
    end

    def fetch_leads_by_id(ids)
      return {} if ids.empty?
      @queries += 1
      Salesforce::Records::Lead
        .select(:id, :accounts_uuid, :is_converted, :converted_contact_id)
        .where(id: ids).index_by(&:id)
    end

    def reconcile_user_by_stored_lead(user, lead)
      if lead.nil?
        finding(user, 'sf_lead_uuid_mismatch', 'Lead', user.salesforce_lead_id, details: { reason: 'missing_in_sf' })
        heal_reattach_via_lookup(user) if @self_heal
        return
      end

      if lead.is_converted && lead.converted_contact_id.present?
        contact = safe_find(Salesforce::Records::Contact, lead.converted_contact_id)
        if contact && Verify.contact_owns_user?(contact, user)
          if @self_heal
            user.update!(salesforce_contact_id: contact.id)
            Audit.record(user, :reconcile_attached_from_conversion, lead_id: lead.id, contact_id: contact.id)
            @metrics.increment(:contacts_attached_from_lead_conversion)
          end
          return
        end
      end

      if lead.accounts_uuid != user.uuid
        finding(user, 'sf_lead_uuid_mismatch', 'Lead', lead.id, details: { uuid_in_sf: lead.accounts_uuid })
        heal_reattach_via_lookup(user) if @self_heal
        return
      end

      Audit.record(user, :reconcile_user_ok, lead_id: lead.id)
    end

    # ----- Pass 3: missing-link discovery ----- #

    def run_pass_3
      scope = User.where(salesforce_contact_id: nil, salesforce_lead_id: nil)
                  .where(is_profile_complete: true)
                  .where(role: User.roles[:instructor])
                  .where.not(faculty_status: User.faculty_statuses[:rejected_faculty])

      scope.find_in_batches(batch_size: BATCH_SIZE) do |users|
        break if budget_exceeded?
        uuids = users.map(&:uuid)
        @queries += 2
        contacts_by_uuid = Salesforce::Records::Contact.where(accounts_uuid: uuids).index_by(&:accounts_uuid)
        leads_by_uuid    = Salesforce::Records::Lead.where(accounts_uuid: uuids).index_by(&:accounts_uuid)

        users.each { |u| attach_missing_link(u, contacts_by_uuid[u.uuid], leads_by_uuid[u.uuid]) }
        @metrics.increment(:users_pass_3, by: users.size)
      end
    end

    def attach_missing_link(user, contact, lead)
      if contact && Verify.contact_owns_user?(contact, user)
        if @self_heal
          user.update!(salesforce_contact_id: contact.id)
          Audit.record(user, :link_restored_by_reconcile, contact_id: contact.id, via: :pass_3)
          @metrics.increment(:links_restored)
        end
        return
      end

      if lead && Verify.lead_owns_user?(lead, user) && !lead.is_converted
        if @self_heal
          user.update!(salesforce_lead_id: lead.id)
          Audit.record(user, :link_restored_by_reconcile, lead_id: lead.id, via: :pass_3)
          @metrics.increment(:links_restored)
        end
        return
      end

      finding(user, 'user_unlinked_eligible', nil, nil)
      @metrics.increment(:unlinked_eligible)
    end

    # ----- SF-orphan sweep ----- #

    def sweep_sf_orphans
      return if budget_exceeded?

      since = SWEEP_LOOKBACK.ago.utc.iso8601
      @queries += 2

      contact_uuids = pluck_accounts_uuids(Salesforce::Records::Contact, since)
      lead_uuids    = pluck_accounts_uuids(Salesforce::Records::Lead, since)

      all_uuids = (contact_uuids + lead_uuids).uniq
      known = User.where(uuid: all_uuids).pluck(:uuid).to_set

      (contact_uuids.uniq - known.to_a).each do |uuid|
        finding(nil, 'sf_orphan_contact', 'Contact', nil, details: { accounts_uuid: uuid })
      end
      (lead_uuids.uniq - known.to_a).each do |uuid|
        finding(nil, 'sf_orphan_lead', 'Lead', nil, details: { accounts_uuid: uuid })
      end
    end

    def pluck_accounts_uuids(klass, since)
      klass.select(:id, :accounts_uuid)
        .where("Accounts_UUID__c != null AND LastModifiedDate >= #{since}")
        .pluck(:accounts_uuid)
        .compact
    rescue StandardError => e
      Sentry.capture_exception(e)
      []
    end

    # ----- Finalize ----- #

    def finalize_findings
      cutoff = @metrics.started_at
      closed = SalesforceDriftFinding.open.where('last_seen_at < ?', cutoff).update_all(resolved_at: Time.current)
      @metrics.increment(:findings_closed, by: closed)

      SalesforceDriftFinding.resolved.where('resolved_at < ?', 60.days.ago).delete_all

      total_open = SalesforceDriftFinding.open.count
      @metrics.increment(:findings_total_open, by: total_open) if total_open > 0

      threshold = Settings::Salesforce.alert_drift_open_total
      if total_open > threshold
        @metrics.alert!(:drift_findings_total_open, value: total_open, threshold: threshold)
      end
    end

    # ----- Helpers ----- #

    def finding(user, category, type, id, details: {})
      SalesforceDriftFinding.upsert_finding!(
        category: category, user: user,
        record_type: type, record_id: id, details: details
      )
      @metrics.increment(:findings_opened, category: category)
    end

    def close_findings(user, category:)
      SalesforceDriftFinding.open.where(user: user, category: category)
        .update_all(resolved_at: Time.current)
    end

    def budget_exceeded?
      if @queries >= @max_queries
        @metrics.alert!(:reconcile_budget_exceeded, value: @queries, threshold: @max_queries)
        true
      else
        false
      end
    end

    def safe_find(klass, id)
      klass.find(id)
    rescue StandardError
      nil
    end

    def log(msg)
      Rails.logger.tagged(self.class.name) { Rails.logger.info(msg) }
    end
  end
end
