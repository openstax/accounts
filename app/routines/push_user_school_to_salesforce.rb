# Propagates a school change made through UpdateSelfReportedSchool to whichever
# Salesforce record the user is already linked to. A user linked to none of the
# three gets no write -- same rule as PushUserActivityToSalesforce passes 2 and
# 3, which refuse to create a record whose only content is one synced field.
#
# Outside production `perform_later` runs inline inside UpdateSelfReportedSchool's
# transaction, so a Salesforce failure has to be swallowed there or it would roll
# back the user's school change. In a real delayed job it must raise instead, so
# the worker retries.
class PushUserSchoolToSalesforce

  lev_routine active_job_enqueue_options: { queue: :salesforce }

  uses_routine Newflow::UpdateExistingSalesforceLead

  FALLBACK_SCHOOL_NAME = 'Find Me A Home'.freeze

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

  def push_student_school(user)
    return unless Settings::Salesforce.push_students_enabled

    succeeded = set_student_school(user)
    return if succeeded || !retry_on_failure?

    raise_retryable_failure!('student school update failed', user)
  end

  # Fill-in-blanks, mirroring PushUserActivityToSalesforce#link_or_create: an
  # Assignable LMS-derived school beats a signup-form pick.
  def set_student_school(user)
    student = OpenStax::Salesforce::Remote::Student.find(user.salesforce_student_id)
    return true if student.nil? || student.school_id.present?

    sf_school_id = user.school&.salesforce_id || fallback_school_id(user)
    return true if sf_school_id.nil?

    student.school_id = sf_school_id
    student.save!
  rescue StandardError => e
    report(user, 'student school update failed', e)
    false
  end

  def push_contact_school(user)
    return unless Settings::Salesforce.push_leads_enabled

    succeeded = set_contact_school(user)
    return if succeeded || !retry_on_failure?

    raise_retryable_failure!('contact school update failed', user)
  end

  # The one path allowed to move a Contact's AccountId (see CLAUDE.md's narrowed
  # Salesforce boundary). A resolved school overwrites, but an unresolved one
  # only fills a blank: moving a Contact off an Account Customer Experience may
  # have set deliberately, onto the review bucket, is worse than doing nothing.
  def set_contact_school(user)
    contact = OpenStax::Salesforce::Remote::Contact.find(user.salesforce_contact_id)
    return true if contact.nil?

    sf_school_id = user.school&.salesforce_id
    if sf_school_id.blank?
      return true if contact.school_id.present?

      sf_school_id = fallback_school_id(user)
      return true if sf_school_id.nil?
    end

    contact.school_id = sf_school_id
    contact.save!
  rescue StandardError => e
    report(user, 'contact school update failed', e)
    false
  end

  # Memoized through `defined?` so a nil result is cached too. A missing
  # fallback Account is a data problem, not a transient failure, so it skips
  # the write rather than raising into a user's profile save.
  def fallback_school_id(user)
    return @fallback_school_id if defined?(@fallback_school_id)

    @fallback_school_id =
      OpenStax::Salesforce::Remote::School.find_by(name: FALLBACK_SCHOOL_NAME)&.id

    if @fallback_school_id.nil?
      Sentry.capture_message(
        "Salesforce '#{FALLBACK_SCHOOL_NAME}' school not found; " \
        "skipping school push for user #{user.id}"
      )
    end

    @fallback_school_id
  end

  # UpdateExistingSalesforceLead re-finds the lead, follows conversion, and lets
  # CreateOrUpdateSalesforceLead write the school fields and its own fallback.
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

  def report(user, what, error)
    Sentry.capture_message(
      "Salesforce #{what} for user #{user.id}: #{error.class.name}: #{error.message}"
    )
  end
end
