# Nightly (cron:day) pass that keeps educators who stalled mid-signup visible
# in Salesforce, then resyncs everyone's faculty_status from their Lead.
#
# Pass 1 creates a Lead for educators who never got one and never converted
# straight to a Contact -- e.g. someone who bailed before reaching SheerID, or
# whose lead push failed silently. Bounded and gated: this writes new records
# to Salesforce, unlike the read-only sync in pass 2.
class SyncEducatorLeads
  LEAD_BATCH_LIMIT = 500
  STALLED_SIGNUP_CUTOFF = 24.hours
  # Older accounts with no Lead are history, not stalled signups; a reminder
  # would make no sense to them and a Lead would only add noise to the queue.
  STALLED_SIGNUP_MAX_AGE = 90.days

  def self.call
    new.call
  end

  def call
    create_stalled_signup_leads
    UpdateUserLeadInfo.call
  end

  def create_stalled_signup_leads
    return unless Settings::Salesforce.push_incomplete_signup_leads_enabled

    stalled_signup_users.each { |user| create_lead_for(user) }
  end

  # Backed by index_users_stalled_educator_signups.
  def stalled_signup_users
    User.where.not(role: :student)
        .where.not(role: :unknown_role)
        .where(state: 'activated', is_newflow: true, salesforce_lead_id: nil, salesforce_contact_id: nil)
        .where(created_at: STALLED_SIGNUP_MAX_AGE.ago..STALLED_SIGNUP_CUTOFF.ago)
        .order(:created_at)
        .limit(LEAD_BATCH_LIMIT)
  end

  def create_lead_for(user)
    result = Newflow::CreateOrUpdateSalesforceLead.call(user: user)
    return unless result.outputs.lead_saved

    SecurityLog.create!(
      user: user,
      event_type: :incomplete_signup_lead_created,
      event_data: { lead_id: result.outputs.lead&.id }
    )
  rescue StandardError => e
    Sentry.capture_exception(e, extra: { user_id: user.id })
  end
end
