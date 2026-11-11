# Pushes a user's "Report an adoption" submissions to Salesforce by writing
# AdoptionsJSON__c and Tracking_Parameters__c on their Contact (or Lead, while
# they are pending verification). Salesforce picks the payload up about five
# minutes later and creates the Opportunity and Adoption__c; Salesforce::AdoptionSync
# imports that adoption nightly, so it reaches the Impact tab the next day.
#
# Call with a specific user to push just their reports (e.g. right after they
# save one), or with no user to sweep every user who has unpushed reports
# (e.g. from the daily cron, so a failed push gets retried).
class PushAdoptionReports

  lev_routine transaction: :no_transaction, active_job_enqueue_options: { queue: :salesforce }

  CONTACT_TARGET = 'Contact'.freeze
  LEAD_TARGET = 'Lead'.freeze
  DEFAULT_SURFACE = 'books'.freeze
  BRACKETED_SUFFIX = /\s*\[([^\]]*)\]\s*\z/

  private_constant(:CONTACT_TARGET, :LEAD_TARGET, :DEFAULT_SURFACE, :BRACKETED_SUFFIX)

  def self.call_for_all_unpushed
    call(user: nil)
  end

  protected #################

  def exec(user: nil)
    status.set_job_name(self.class.name)
    status.set_job_args(user: user&.to_global_id.to_s)

    unless Settings::Salesforce.push_adoption_reports_enabled
      log(:info, 'disabled (push_adoption_reports_enabled); skipping')
      outputs.pushed_user_count = 0
      return
    end

    users = user ? [user] : users_with_unpushed_reports
    outputs.pushed_user_count = users.count { |a_user| push_for_user(a_user) }
  end

  private #################

  def users_with_unpushed_reports
    User.where(id: AdoptionReport.pushable.select(:user_id).distinct)
  end

  # One payload per user, holding all of that user's unpushed reports. Any
  # failure is reported and swallowed so it can't stop a sweep; the reports
  # stay unpushed for the next run.
  def push_for_user(user)
    reports = user.adoption_reports.pushable.order(:id).to_a
    return false if reports.empty?

    record, target = resolve_target(user)
    return false unless record

    if target == CONTACT_TARGET && adoption_json_pending?(record.id)
      log(:info, "skipping user_id=#{user.id}: previous payload still pending in Salesforce")
      return false
    end

    record.adoption_json = adoption_json_for(reports)
    record.tracking_parameters = tracking_parameters_for(reports)

    unless record.save
      Sentry.capture_message('PushAdoptionReports: Salesforce save failed',
                             level: :warning, extra: { user_id: user.id, target: target })
      return false
    end

    AdoptionReport.where(id: reports.map(&:id)).update_all(salesforce_pushed_at: Time.zone.now)
    SecurityLog.create!(user: user, event_type: :adoption_reports_pushed_to_salesforce,
                        event_data: { target: target, report_count: reports.size })
    true
  rescue StandardError => e
    log(:warn, "error pushing adoption reports for user_id=#{user.id}: #{e.class}")
    Sentry.capture_exception(e, extra: { user_id: user.id })
    false
  end

  # Contact first (confirmed instructors always have one), then Lead, then a new
  # lead through the signup routine. Returns [remote record, target name] or nil.
  def resolve_target(user, create_lead: true)
    return [OpenStax::Salesforce::Remote::Contact.find(user.salesforce_contact_id), CONTACT_TARGET] if user.salesforce_contact_id.present?

    if user.salesforce_lead_id.present?
      lead = OpenStax::Salesforce::Remote::Lead.find(user.salesforce_lead_id)
      return [lead, LEAD_TARGET] unless lead.is_converted && lead.converted_contact_id.present?

      user.update!(salesforce_contact_id: lead.converted_contact_id)
      return resolve_target(user, create_lead: false)
    end

    return unless create_lead && Settings::Salesforce.push_leads_enabled

    Newflow::CreateOrUpdateSalesforceLead.call(user: user)
    user.reload
    return resolve_target(user, create_lead: false) if user.salesforce_lead_id.present?

    # The lead routine reports its own failures and skips roles it never pushes
    # (students, self_learner), so this is logged rather than sent to Sentry nightly.
    log(:info, "skipping user_id=#{user.id}: no Salesforce lead")
    nil
  end

  # A second payload arriving while the first is still being processed can be lost.
  def adoption_json_pending?(contact_id)
    soql = "SELECT Adoption_JSON_Pending__c FROM Contact WHERE Id = '#{contact_id.to_s.gsub(/['\\]/) { |c| "\\#{c}" }}'"
    row = OpenStax::Salesforce::Remote::Contact.sfdc_client.query(soql).first
    ActiveModel::Type::Boolean.new.cast(row && row['Adoption_JSON_Pending__c']) == true
  end

  def adoption_json_for(reports)
    { 'Books' => reports.map { |report| book_json_for(report) } }.to_json
  end

  # Salesforce matches name against Book__c, so it is the CMS salesforce_abbreviation.
  # Spanish editions carry a " [Spanish]" suffix that belongs in language instead.
  def book_json_for(report)
    name = report.salesforce_book_name
    {
      name: name.sub(BRACKETED_SUFFIX, ''),
      students: report.students,
      howUsing: report.how_using || AdoptionReport::HOW_USING_OPTIONS.first,
      language: name[BRACKETED_SUFFIX, 1].presence || 'English',
      baseYear: report.school_year_start
    }
  end

  # Salesforce's Create_Adoptions flow copies this onto the new Adoption__c, so it
  # names the page of the most recent report in the payload.
  def tracking_parameters_for(reports)
    surface = reports.max_by(&:updated_at).surface.presence || DEFAULT_SURFACE
    "#{Rails.application.secrets.openstax_url}/accounts/i/account/#{surface}?related=MyOpenStax"
  end

  def log(level, message)
    Rails.logger.public_send(level, "[PushAdoptionReports] #{message}")
  end

end
