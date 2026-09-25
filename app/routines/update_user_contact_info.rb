class UpdateUserContactInfo
  class UnknownFacultyVerifiedError < StandardError; end

  CHECK_IN_SLUG = 'update-user-contact-info'.freeze
  # Keep in sync with the `cron:10-to-half-hour` schedule in config/schedule.rb.
  MONITOR_CONFIG = Sentry::Cron::MonitorConfig.from_crontab(
    '20,50 * * * *', checkin_margin: 30, max_runtime: 120, timezone: 'UTC'
  )
  BATCH_SIZE = 2000
  WATERMARK_OVERLAP = 15.minutes

  COLLEGE_TYPES = [
    'College/University (4)',
    'Technical/Community College (2)',
    'Career School/For-Profit (2)'
  ].freeze
  HIGH_SCHOOL_TYPES = ['High School'].freeze
  K12_TYPES = ['K-12 School'].freeze
  HOME_SCHOOL_TYPES = ['Home School'].freeze

  DOMESTIC_SCHOOL_LOCATIONS = ['Domestic'].freeze
  FOREIGN_SCHOOL_LOCATIONS = ['Foreign'].freeze

  ADOPTION_STATUSES = {
    'Current Adopter' => true,
    'Future Adopter' => true,
    'Past Adopter' => true,
    'Not Adopter' => false
  }.freeze

  # Don't overwrite confirmed or pending faculty status with incomplete/no_info.
  # Don't overwrite confirmed with pending. Don't overwrite rejected_faculty
  # with incomplete/no_info.
  NO_DOWNGRADE_STATUSES = {
    'confirmed_faculty' => %w[pending_faculty incomplete_signup no_faculty_info],
    'pending_faculty' => %w[incomplete_signup no_faculty_info],
    'rejected_faculty' => %w[incomplete_signup no_faculty_info]
  }.freeze

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
    log("Starting sync with Salesforce (since #{since.utc.iso8601})")

    log_summary(run_pages(since))

    # The watermark is the run's start time, not its end time, so a Contact
    # modified while this run was in flight isn't skipped by the next run.
    Settings::Salesforce.contacts_synced_through = run_started_at
    succeeded = true
  ensure
    Sentry.capture_check_in(CHECK_IN_SLUG, succeeded ? :ok : :error, check_in_id: check_in_id)
  end

  def run_pages(since)
    totals = { updated: 0, fv_status_changed: 0, without_cached_school: 0, failed: 0, pages: 0 }
    after_id = nil

    loop do
      totals[:pages] += 1
      contacts = salesforce_contact_batch(since: since, after_id: after_id)
      process_contacts(contacts).each do |key, value|
        totals[key] += value
      end

      break if contacts.length < BATCH_SIZE

      after_id = contacts.last.id
    end

    totals
  end

  def log_summary(totals)
    log("Fetched #{totals[:pages]} page(s) from Salesforce.")
    log("Completed updating #{totals[:updated]} users.")
    log("#{totals[:fv_status_changed]} users had their faculty status updated.")
    log(
      "#{totals[:without_cached_school]} users had no cached school in accounts. This should " \
      'update on the next sync (after UpdateSchoolSalesforceInfo runs) or it is missing ' \
      'in Salesforce.'
    )
    log("#{totals[:failed]} users failed to update and were skipped.") if totals[:failed].positive?
  end

  def window_start
    watermark = Settings::Salesforce.contacts_synced_through
    return watermark - WATERMARK_OVERLAP if watermark

    Settings::Db.store.number_of_days_contacts_modified.to_i.days.ago
  end

  def contact_batch_query(since:, after_id: nil)
    query = OpenStax::Salesforce::Remote::Contact
            .select(:id, :email, :faculty_verified, :school_type, :adoption_status, :accounts_uuid)
            .where('Accounts_UUID__c != null')
            .where("LastModifiedDate >= #{since.utc.iso8601}")
    query = query.where('Id > ?', after_id) if after_id.present?
    query.includes(:school).order('Id').limit(BATCH_SIZE)
  end

  def salesforce_contact_batch(since:, after_id: nil)
    contact_batch_query(since: since, after_id: after_id).to_a
  end

  def process_contacts(contacts)
    counts = { updated: 0, fv_status_changed: 0, without_cached_school: 0, failed: 0 }
    return counts if contacts.empty?

    contacts_by_uuid = contacts_by_uuid_hash(contacts)
    users = User.where(uuid: contacts.map(&:accounts_uuid))
    schools_by_salesforce_id = schools_by_salesforce_id_for(contacts_by_uuid)

    log("Updating #{users.count} users from Salesforce")

    users.each do |user|
      process_user(user, contacts_by_uuid[user.uuid], schools_by_salesforce_id, counts)
    end

    counts
  end

  def schools_by_salesforce_id_for(contacts_by_uuid)
    School.select(:id, :salesforce_id).where(
      salesforce_id: contacts_by_uuid.values.compact.map(&:school_id)
    ).index_by(&:salesforce_id)
  end

  # An unknown faculty_verified value or a save! validation failure is
  # isolated to this one user/Contact pair; anything else propagates and
  # fails the run.
  def process_user(user, sf_contact, schools_by_salesforce_id, counts)
    result = update_user_from_contact(user, sf_contact, schools_by_salesforce_id)
    counts[:updated] += 1 if result[:updated]
    counts[:fv_status_changed] += 1 if result[:fv_status_changed]
    counts[:without_cached_school] += 1 if result[:without_cached_school]
  rescue UnknownFacultyVerifiedError, ActiveRecord::RecordInvalid => e
    counts[:failed] += 1
    Sentry.capture_exception(e, extra: { user_id: user.id, salesforce_contact_id: sf_contact.id })
  end

  def update_user_from_contact(user, sf_contact, schools_by_salesforce_id)
    update_salesforce_contact_id!(user, sf_contact)
    fv_status_changed = update_faculty_status!(user, sf_contact)
    without_cached_school = update_school_info!(user, sf_contact, schools_by_salesforce_id)

    updated = false
    updated = user.save! if user.changed?

    {
      updated: updated,
      fv_status_changed: fv_status_changed,
      without_cached_school: without_cached_school
    }
  end

  def update_salesforce_contact_id!(user, sf_contact)
    previous_contact_id = user.salesforce_contact_id
    user.salesforce_contact_id = sf_contact.id
    return if sf_contact.id == previous_contact_id

    SecurityLog.create!(
      user: user,
      event_type: :user_contact_id_updated_from_salesforce,
      event_data: { previous_contact_id: previous_contact_id, new_contact_id: sf_contact.id }
    )
  end

  def update_faculty_status!(user, sf_contact)
    old_fv_status = user.faculty_status
    new_status = faculty_status_from_contact(sf_contact)

    downgrade = NO_DOWNGRADE_STATUSES.fetch(user.faculty_status, []).include?(new_status)
    user.faculty_status = new_status unless downgrade

    return false unless user.faculty_status_changed?

    SecurityLog.create!(
      user: user,
      event_type: :salesforce_updated_faculty_status,
      event_data: {
        user_id: user.id, salesforce_contact_id: sf_contact.id,
        old_status: old_fv_status, new_status: user.faculty_status
      }
    )
    true
  end

  # Maps Salesforce faculty_verified values to our string-based enum values;
  # nil maps to no_faculty_info, unknown values raise an error.
  def faculty_status_from_contact(sf_contact)
    faculty_verified = sf_contact.faculty_verified
    return 'no_faculty_info' if faculty_verified.nil?
    return faculty_verified if User::VALID_FACULTY_STATUSES.include?(faculty_verified)

    raise UnknownFacultyVerifiedError,
          "Unknown faculty_verified field: '#{faculty_verified}' on contact #{sf_contact.id}"
  end

  def update_school_info!(user, sf_contact, schools_by_salesforce_id)
    school = schools_by_salesforce_id[sf_contact.school_id]
    sf_school = sf_contact.school

    user.school_type = map_school_type(sf_contact.school_type)
    user.school_location = map_school_location(sf_school&.school_location)
    apply_adoption_fields!(user, sf_contact, sf_school)

    return true if missing_cached_school?(user, school, sf_school)

    user.school = school
    false
  end

  def missing_cached_school?(user, school, sf_school)
    return false unless school.nil? && !sf_school.nil?

    Sentry.capture_message(
      "User #{user.id} has a school that is in SF but not cached yet #{sf_school.id}"
    )
    true
  end

  # TODO: This can be removed once OSWeb is migated to using the new
  # adopter_status field for renewal forms
  def apply_adoption_fields!(user, sf_contact, sf_school)
    unless sf_contact.adoption_status.blank?
      user.using_openstax = ADOPTION_STATUSES[sf_contact.adoption_status]
    end
    user.adopter_status = sf_contact.adoption_status
    user.is_kip = sf_school&.is_kip || sf_school&.is_child_of_kip
  end

  def map_school_type(sf_school_type)
    case sf_school_type
    when *COLLEGE_TYPES then :college
    when *HIGH_SCHOOL_TYPES then :high_school
    when *K12_TYPES then :k12_school
    when *HOME_SCHOOL_TYPES then :home_school
    when NilClass then :unknown_school_type
    else :other_school_type
    end
  end

  def map_school_location(sf_school_location)
    case sf_school_location
    when *DOMESTIC_SCHOOL_LOCATIONS then :domestic_school
    when *FOREIGN_SCHOOL_LOCATIONS then :foreign_school
    else :unknown_school_location
    end
  end

  def contacts_by_uuid_hash(contacts)
    contacts_by_uuid = {}
    contacts.each do |contact|
      contacts_by_uuid[contact.accounts_uuid] = contact
    end
    contacts_by_uuid
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end
end
