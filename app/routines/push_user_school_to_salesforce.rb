# Propagates a school change made through UpdateSelfReportedSchool to whichever
# Salesforce record the user is already linked to. Three mutually exclusive
# cases, checked in order of how far into Salesforce the user has gotten:
# a linked Student__c, a converted Contact, or an unconverted Lead. A user
# with none of the three gets no Salesforce write -- same reasoning as
# PushUserActivityToSalesforce's passes 2 and 3, which refuse to create a
# record whose only content is one synced field.
#
# In development and test, `perform_later` runs inline inside
# UpdateSelfReportedSchool's transaction (Delayed::Worker.delay_jobs is only
# true in production), so a Salesforce failure must be swallowed there or it
# would roll back the user's school change. In a real delayed job the same
# failure must raise so the worker retries.
class PushUserSchoolToSalesforce

  lev_routine active_job_enqueue_options: { queue: :salesforce }

  uses_routine Newflow::UpdateExistingSalesforceLead

  protected #################

  def exec(user:)
    return unless user

    status.set_job_name(self.class.name)
    status.set_job_args(user: user.to_global_id.to_s)

    if user.student? && user.salesforce_student_id.present?
      push_student_school(user)
    elsif user.salesforce_contact_id.present?
      push_contact_school(user)
    elsif user.salesforce_lead_id.present?
      push_lead_school(user)
    end
  end

  private ###################

  # Mirrors PushUserActivityToSalesforce#link_or_create: an Assignable
  # LMS-derived school beats a signup-form pick, so School__c is filled in
  # only when Salesforce doesn't already have one -- never overwritten,
  # never cleared. Free text has no Account id to write, so it's skipped.
  def push_student_school(user)
    return unless Settings::Salesforce.push_students_enabled

    sf_school_id = user.school&.salesforce_id
    return if sf_school_id.blank?

    succeeded = set_student_school(user, sf_school_id)
    return if succeeded || !retry_on_failure?

    raise_retryable_failure!('student school update failed', user)
  end

  def set_student_school(user, sf_school_id)
    student = OpenStax::Salesforce::Remote::Student.find(user.salesforce_student_id)
    return true if student.nil? || student.school_id.present?

    student.school_id = sf_school_id
    student.save!
  rescue StandardError => e
    report(user, 'student school update failed', e)
    false
  end

  # The one path allowed to move AccountId on a Contact (see CLAUDE.md's
  # narrowed Salesforce boundary) -- overwrites outright, since this is an
  # explicit school change, not the wholesale lead/contact resync that must
  # never reparent a Contact. Free text has no Account to point at, and
  # never clears an existing AccountId: a user backing out to free text must
  # not orphan their Contact from whatever school it already has.
  def push_contact_school(user)
    return unless Settings::Salesforce.push_leads_enabled

    sf_school_id = user.school&.salesforce_id
    return if sf_school_id.blank?

    succeeded = set_contact_school(user, sf_school_id)
    return if succeeded || !retry_on_failure?

    raise_retryable_failure!('contact school update failed', user)
  end

  def set_contact_school(user, sf_school_id)
    contact = OpenStax::Salesforce::Remote::Contact.find(user.salesforce_contact_id)
    return true if contact.nil?

    contact.school_id = sf_school_id
    contact.save!
  rescue StandardError => e
    report(user, 'contact school update failed', e)
    false
  end

  # CreateOrUpdateSalesforceLead already writes self_reported_school,
  # school, city, state/state_code, country and account_id from the user's
  # current school, and UpdateExistingSalesforceLead already re-finds the
  # lead, follows a since-converted lead to its Contact, and applies its own
  # retry/swallow rules -- no field assignment or retry handling belongs here.
  def push_lead_school(user)
    return unless Settings::Salesforce.push_leads_enabled

    run(Newflow::UpdateExistingSalesforceLead, user: user)
  end

  def retry_on_failure?
    Delayed::Worker.delay_jobs
  end

  def raise_retryable_failure!(what, user)
    raise StandardError, "Salesforce #{what} for user #{user.id}"
  end

  # Sentry rather than SecurityLog: this runs inside the caller's transaction,
  # which may roll back, and an unreachable Salesforce isn't an account-audit
  # event.
  def report(user, what, error)
    Sentry.capture_message(
      "Salesforce #{what} for user #{user.id}: #{error.class.name}: #{error.message}"
    )
  end
end
