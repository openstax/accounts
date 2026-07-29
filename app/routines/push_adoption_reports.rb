# Pushes a user's locally-collected AdoptionReports (from the "Report an
# adoption" modal / annual check-in) to Salesforce by reusing the same public
# adoption-form handler os-webview posts to. Salesforce-side automation keyed
# on process_adoptions=true turns the payload into Opportunity/Adoption__c
# records, so from here we just have to speak the form's language.
#
# Call with a specific user to push just their reports (e.g. right after they
# save one), or with no user to sweep every user who has unpushed reports
# (e.g. from the daily cron, so a failed push gets retried).
class PushAdoptionReports

  lev_routine transaction: :no_transaction, active_job_enqueue_options: { queue: :salesforce }

  # Faraday POST is made per-user, outside of any DB transaction, so a slow or
  # failing request for one user can't hold a transaction open or roll back
  # another user's already-recorded push.
  HTTP_TIMEOUT = 10 # seconds, for both open and read

  # lead_source is a fixed string for now; the DATA team may later want a
  # dedicated value (e.g. "My OpenStax") to distinguish reports pushed from
  # in-product forms from the public openstax.org adoption form.
  LEAD_SOURCE = 'Adoption Form'

  DEFAULT_HOW_USING = 'As the core textbook for my course'

  POSITION_BY_ROLE = {
    'instructor' => 'Faculty',
    'administrator' => 'Administrator',
    'librarian' => 'Librarian',
    'designer' => 'Instructional Designer',
    'adjunct' => 'Adjunct Faculty',
    'homeschool' => 'Home School Teacher'
  }.freeze

  private_constant(:HTTP_TIMEOUT, :LEAD_SOURCE, :DEFAULT_HOW_USING, :POSITION_BY_ROLE)

  def self.call_for_all_unpushed
    call(user: nil)
  end

  protected #################

  # user: nil sweeps every user with unpushed reports; a specific user pushes
  # only that user's unpushed reports.
  def exec(user: nil)
    status.set_job_name(self.class.name)
    status.set_job_args(user: user&.to_global_id.to_s)

    unless enabled?
      log(:info, 'disabled or unconfigured (push_adoption_reports_enabled / adoption_form_posting_url); skipping')
      outputs.pushed_user_count = 0
      return
    end

    users = user ? [user] : users_with_unpushed_reports
    pushed_user_count = 0

    users.each do |a_user|
      pushed_user_count += 1 if push_for_user(a_user)
    end

    outputs.pushed_user_count = pushed_user_count
  end

  private #################

  def enabled?
    Settings::Salesforce.push_adoption_reports_enabled &&
      Settings::Salesforce.adoption_form_posting_url.present?
  end

  def users_with_unpushed_reports
    # AdoptionReports with status 'not_using' are deliberately excluded here
    # (and below, via the .using scope) — the form handler has no vocabulary
    # for removals, so those stay local only.
    User.where(id: AdoptionReport.unpushed.using.select(:user_id).distinct)
  end

  # One POST per user, batching all of that user's unpushed reports into a
  # single adoption_json payload, matching how the web form itself batches
  # multiple books/years in one submission. Any failure for this user
  # (network error, non-2xx, etc.) is caught and logged so it doesn't stop
  # the rest of a sweep; the reports are simply left unpushed for next time.
  def push_for_user(user)
    reports = user.adoption_reports.unpushed.using.to_a
    return false if reports.empty?

    email = verified_email_for(user)
    name_present = user.full_name.present?

    if email.blank? || !name_present
      log(:warn, "skipping user_id=#{user.id}: missing verified email or name (#{reports.size} unpushed reports)")
      return false
    end

    response = post_reports(user: user, email: email, reports: reports)

    if response && (200..299).cover?(response.status)
      mark_pushed(reports)
      true
    else
      log(:warn, "non-2xx response for user_id=#{user.id} status=#{response&.status}")
      false
    end
  rescue Faraday::Error => e
    log(:warn, "Faraday error pushing adoption reports for user_id=#{user.id}: #{e.class}")
    Sentry.capture_exception(e, extra: { user_id: user.id })
    false
  rescue StandardError => e
    log(:warn, "unexpected error pushing adoption reports for user_id=#{user.id}: #{e.class}")
    Sentry.capture_exception(e, extra: { user_id: user.id })
    false
  end

  def verified_email_for(user)
    user.email_addresses.verified.first&.value
  end

  def mark_pushed(reports)
    AdoptionReport.where(id: reports.map(&:id)).update_all(salesforce_pushed_at: Time.zone.now)
  end

  def post_reports(user:, email:, reports:)
    form = {
      first_name: user.first_name,
      last_name: user.last_name,
      email: email,
      school: user.most_accurate_school_name,
      role: 'Instructor',
      position: position_for(user),
      lead_source: LEAD_SOURCE,
      process_adoptions: 'true',
      subject_interest: reports.map(&:book_title).join('; '),
      adoption_json: adoption_json_for(reports)
    }
    form[:salesforce_contact_id] = user.salesforce_contact_id if user.salesforce_contact_id.present?

    connection.post(Settings::Salesforce.adoption_form_posting_url, form)
  end

  def position_for(user)
    POSITION_BY_ROLE.fetch(user.role.to_s, 'Other')
  end

  def adoption_json_for(reports)
    books = reports.map do |report|
      {
        name: report.book_title,
        students: report.students,
        howUsing: DEFAULT_HOW_USING,
        language: 'English',
        baseYear: report.school_year_start
      }
    end

    { 'Books' => books }.to_json
  end

  def connection
    @connection ||= Faraday.new(request: { open_timeout: HTTP_TIMEOUT, timeout: HTTP_TIMEOUT }) do |f|
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end
  end

  def log(level, message)
    Rails.logger.public_send(level, "[PushAdoptionReports] #{message}")
  end

end
