class UpdateUserLeadInfo
  class UnknownVerificationStatusError < StandardError; end

  CHECK_IN_SLUG = 'update-user-lead-info'.freeze
  # Keep in sync with the `cron:day` schedule in config/schedule.rb (2:30 AM CST).
  MONITOR_CONFIG = Sentry::Cron::MonitorConfig.from_crontab(
    '30 8 * * *', checkin_margin: 30, max_runtime: 120, timezone: 'UTC'
  )
  BATCH_SIZE = 2000
  WATERMARK_OVERLAP = 15.minutes
  DEFAULT_LOOKBACK_DAYS = 7

  def self.call
    new.call
  end

  def call
    check_in_id = Sentry.capture_check_in(
      CHECK_IN_SLUG, :in_progress, monitor_config: MONITOR_CONFIG
    )
    succeeded = false

    run_started_at = Time.current
    since = window_start
    log("Starting lead sync with Salesforce (since #{since.utc.iso8601})")

    log_summary(run_pages(since))

    # The watermark is the run's start time, not its end time, so a Lead
    # modified while this run was in flight isn't skipped by the next run.
    Settings::Salesforce.leads_synced_through = run_started_at
    succeeded = true
  ensure
    Sentry.capture_check_in(CHECK_IN_SLUG, succeeded ? :ok : :error, check_in_id: check_in_id)
  end

  def run_pages(since)
    totals = { updated: 0, fv_status_changed: 0, failed: 0, pages: 0 }
    after_id = nil

    loop do
      totals[:pages] += 1
      leads = salesforce_lead_batch(since: since, after_id: after_id)
      process_leads(leads).each do |key, value|
        totals[key] += value
      end

      break if leads.length < BATCH_SIZE

      after_id = leads.last.id
    end

    totals
  end

  def log_summary(totals)
    log("Fetched #{totals[:pages]} page(s) from Salesforce.")
    log("Completed updating #{totals[:updated]} users.")
    log("#{totals[:fv_status_changed]} users had their faculty status updated.")
    log("#{totals[:failed]} users failed to update and were skipped.") if totals[:failed].positive?
  end

  def window_start
    watermark = Settings::Salesforce.leads_synced_through
    return watermark - WATERMARK_OVERLAP if watermark

    DEFAULT_LOOKBACK_DAYS.days.ago.beginning_of_day
  end

  def lead_batch_query(since:, after_id: nil)
    query = OpenStax::Salesforce::Remote::Lead
            .select(:id, :accounts_uuid, :verification_status)
            .where('Accounts_UUID__c != null')
            .where('IsConverted = false')
            .where("LastModifiedDate >= #{since.utc.iso8601}")
    query = query.where('Id > ?', after_id) if after_id.present?
    query.order('Id').limit(BATCH_SIZE)
  end

  def salesforce_lead_batch(since:, after_id: nil)
    lead_batch_query(since: since, after_id: after_id).to_a
  end

  def process_leads(leads)
    counts = { updated: 0, fv_status_changed: 0, failed: 0 }
    return counts if leads.empty?

    leads_by_uuid = leads_by_uuid_hash(leads)
    users = users_for_leads(leads)

    log("Updating #{users.count} users from Salesforce leads")

    users.each do |user|
      process_user(user, leads_by_uuid[user.uuid], counts)
    end

    counts
  end

  # Excludes the student+rejected_faculty marker a mid-signup role switch
  # leaves behind (see CLAUDE.md "Switching account type mid-signup") -- a
  # stale Lead re-syncing that pair would erase the only record of the switch.
  def users_for_leads(leads)
    User.where(uuid: leads.map(&:accounts_uuid))
        .where.not(role: :student, faculty_status: :rejected_faculty)
  end

  # An unknown verification_status value or a save! validation failure is
  # isolated to this one user/Lead pair; anything else propagates and fails
  # the run.
  def process_user(user, lead, counts)
    result = ActiveRecord::Base.transaction(requires_new: true) do
      update_user_from_lead(user, lead)
    end
    counts[:updated] += 1 if result[:updated]
    counts[:fv_status_changed] += 1 if result[:fv_status_changed]
  rescue UnknownVerificationStatusError, ActiveRecord::RecordInvalid => e
    counts[:failed] += 1
    Sentry.capture_exception(e, extra: { user_id: user.id, salesforce_lead_id: lead.id })
  end

  def update_user_from_lead(user, lead)
    id_changed = update_salesforce_lead_id!(user, lead)
    fv_status_changed = update_faculty_status!(user, lead)

    # advance_faculty_status! persists via update! only when it actually moves
    # the record; a refused move or a same-rank no-op leaves a pending
    # salesforce_lead_id change unsaved.
    user.save! if user.changed?

    { updated: id_changed || fv_status_changed, fv_status_changed: fv_status_changed }
  end

  def update_salesforce_lead_id!(user, lead)
    previous_lead_id = user.salesforce_lead_id
    user.salesforce_lead_id = lead.id
    return false if lead.id == previous_lead_id

    SecurityLog.create!(
      user: user,
      event_type: :user_lead_id_updated_from_salesforce,
      event_data: { previous_lead_id: previous_lead_id, new_lead_id: lead.id }
    )
    true
  end

  # Moves faculty_status through the ladder; a refused downgrade is already
  # logged by FacultyStatusLadder (via User#advance_faculty_status!) and needs
  # nothing further here.
  def update_faculty_status!(user, lead)
    old_status = user.faculty_status
    new_status = faculty_status_from_lead(lead)

    advanced = user.advance_faculty_status!(
      new_status, source: :salesforce, event_data: { lead_id: lead.id }
    )
    return false unless advanced
    return false if user.faculty_status == old_status

    SecurityLog.create!(
      user: user,
      event_type: :salesforce_lead_status_synced,
      event_data: {
        user_id: user.id, salesforce_lead_id: lead.id,
        old_status: old_status, new_status: user.faculty_status
      }
    )
    true
  end

  # Maps Salesforce FV_Status__c values to our string-based enum values by
  # name; nil maps to no_faculty_info, unknown values raise an error.
  def faculty_status_from_lead(lead)
    status = lead.verification_status
    return User::NO_FACULTY_INFO if status.nil?
    return status if User::VALID_FACULTY_STATUSES.include?(status)

    raise UnknownVerificationStatusError,
          "Unknown FV_Status__c field: '#{status}' on lead #{lead.id}"
  end

  def leads_by_uuid_hash(leads)
    leads_by_uuid = {}
    leads.each do |lead|
      leads_by_uuid[lead.accounts_uuid] = lead
    end
    leads_by_uuid
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end
end
