module Salesforce
  # Every-30-min incremental sync of Salesforce Contacts into Accounts users.
  # Replaces UpdateUserContactInfo's body. Cursor-driven (with overlap),
  # skips merged/deleted contacts at fetch time, gates every
  # salesforce_contact_id swap on Verify.contact_can_be_replaced? evidence.
  class SyncContacts
    SLUG = 'update-user-contact-info'.freeze

    COLLEGE_TYPES     = ['College/University (4)', 'Technical/Community College (2)', 'Career School/For-Profit (2)'].freeze
    HIGH_SCHOOL_TYPES = ['High School'].freeze
    K12_TYPES         = ['K-12 School'].freeze
    HOME_SCHOOL_TYPES = ['Home School'].freeze

    DOMESTIC_SCHOOL_LOCATIONS = ['Domestic'].freeze
    FOREIGN_SCHOOL_LOCATIONS  = ['Foreign'].freeze

    ADOPTION_STATUSES = {
      'Current Adopter' => true,
      'Future Adopter'  => true,
      'Past Adopter'    => true,
      'Not Adopter'     => false
    }.freeze

    def self.call
      new.call
    end

    def call
      @metrics = Metrics.new(run: 'sync_contacts', slug: SLUG)
      @metrics.start!
      log 'Starting Salesforce contact sync'

      window_start = compute_window_start
      log "Window start: #{window_start.iso8601}"
      check_cron_drift(window_start)

      run_started_at = Time.current
      contacts = fetch_contacts(window_start)
      @metrics.increment(:contacts_fetched, by: contacts.size)
      log "#{contacts.size} contacts fetched"

      uuids = contacts.map(&:accounts_uuid).compact.uniq
      users_by_uuid = User.where(uuid: uuids).index_by(&:uuid)
      schools_by_sf_id = School
        .where(salesforce_id: contacts.map { |c| c.school&.id }.compact)
        .index_by(&:salesforce_id)

      @verify_cache = {}

      contacts.each { |sf_contact| process_contact(sf_contact, users_by_uuid, schools_by_sf_id) }

      Settings::Salesforce.contacts_synced_through = run_started_at
      emit_threshold_alerts
      @metrics.emit(status: :ok)
    rescue StandardError => e
      Sentry.capture_exception(e)
      @metrics.emit(status: :error, extra: { error: e.class.name, message: e.message })
      raise
    end

    private

    def compute_window_start
      cursor = Settings::Salesforce.contacts_synced_through ||
               Settings::Db.store.number_of_days_contacts_modified.to_i.days.ago
      cursor - Settings::Salesforce.contacts_lookback_overlap_hours.hours
    end

    def check_cron_drift(window_start)
      age_hours = ((Time.current - window_start) / 3600.0).to_i
      threshold = Settings::Salesforce.alert_cron_drift_hours
      @metrics.alert!(:cron_drift, value: age_hours, threshold: threshold) if age_hours > threshold * 2
    end

    def fetch_contacts(since)
      Salesforce::Records::Contact.select(
        :id, :email, :faculty_verified, :school_type, :adoption_status,
        :accounts_uuid, :master_record_id, :is_deleted
      ).where("Accounts_UUID__c != null")
       .where("LastModifiedDate >= #{since.utc.iso8601}")
       .includes(:school)
       .to_a
    end

    def process_contact(sf_contact, users_by_uuid, schools_by_sf_id)
      user = users_by_uuid[sf_contact.accounts_uuid]
      unless user
        @metrics.increment(:unknown_accounts_uuids)
        return
      end

      if sf_contact.master_record_id.present? || sf_contact.is_deleted
        @metrics.increment(:contacts_skipped_merged_or_deleted)
        Audit.record(user, :contact_skipped_merged_or_deleted,
                     contact_id: sf_contact.id,
                     master_record_id: sf_contact.master_record_id,
                     is_deleted: sf_contact.is_deleted)
        return
      end

      apply(user, sf_contact, schools_by_sf_id)
      @metrics.increment(:users_matched)
    end

    def apply(user, sf_contact, schools_by_sf_id)
      previous = user.salesforce_contact_id

      if previous.blank?
        user.salesforce_contact_id = sf_contact.id
      elsif previous != sf_contact.id
        return unless safe_to_swap?(user, sf_contact, previous)
      end

      apply_faculty_status(user, sf_contact)
      apply_school_and_type(user, sf_contact, schools_by_sf_id)
      apply_adoption_status(user, sf_contact)

      if user.changed?
        user.save!
        @metrics.increment(:users_updated)
      end
    end

    def safe_to_swap?(user, sf_contact, previous)
      reason = @verify_cache[previous] ||= Verify.contact_can_be_replaced?(
        previous_id: previous, by: sf_contact, user: user
      )
      case reason
      when :gone, :merged, :uuid_cleared
        Audit.record(user, :contact_id_swapped, from: previous, to: sf_contact.id, reason: reason)
        @metrics.increment(:contact_id_swaps, reason: reason)
        user.salesforce_contact_id = sf_contact.id
        true
      else
        Audit.record(user, :contact_id_conflict, stored: previous, candidate: sf_contact.id)
        @metrics.increment(:contact_id_conflicts)
        Sentry.capture_message(
          "Salesforce contact conflict for user #{user.id}: stored=#{previous} candidate=#{sf_contact.id}"
        )
        false
      end
    end

    def apply_faculty_status(user, sf_contact)
      old_status = user.faculty_status
      ResolveFacultyStatus.from_contact(user, sf_contact)
      return unless user.faculty_status_changed?
      @metrics.increment(:users_fv_status_changed)
      Audit.record(user, :updated_faculty_status,
                   user_id: user.id, salesforce_contact_id: sf_contact.id,
                   old_status: old_status, new_status: user.faculty_status)
    end

    def apply_school_and_type(user, sf_contact, schools_by_sf_id)
      user.school_type = case sf_contact.school_type
                         when *COLLEGE_TYPES     then :college
                         when *HIGH_SCHOOL_TYPES then :high_school
                         when *K12_TYPES         then :k12_school
                         when *HOME_SCHOOL_TYPES then :home_school
                         when NilClass           then :unknown_school_type
                         else :other_school_type
                         end

      sf_school = sf_contact.school
      user.school_location = case sf_school&.school_location
                             when *DOMESTIC_SCHOOL_LOCATIONS then :domestic_school
                             when *FOREIGN_SCHOOL_LOCATIONS  then :foreign_school
                             else :unknown_school_location
                             end
      user.is_kip = sf_school&.is_kip || sf_school&.is_child_of_kip

      cached_school = schools_by_sf_id[sf_school&.id]
      if cached_school.nil? && !sf_school.nil?
        @metrics.increment(:users_school_not_cached)
        Audit.record(user, :user_school_not_cached, sf_school_id: sf_school.id)
      else
        user.school = cached_school
      end
    end

    def apply_adoption_status(user, sf_contact)
      unless sf_contact.adoption_status.blank?
        user.using_openstax = ADOPTION_STATUSES[sf_contact.adoption_status]
      end
      user.adopter_status = sf_contact.adoption_status
    end

    def emit_threshold_alerts
      conflicts = @metrics.counters[:contact_id_conflicts].to_i
      threshold_conflicts = Settings::Salesforce.alert_contact_id_conflict_count
      if conflicts > threshold_conflicts
        @metrics.alert!(:contact_id_conflict_count, value: conflicts, threshold: threshold_conflicts)
      end

      updated = @metrics.counters[:users_updated].to_i
      swaps_counter = @metrics.counters[:contact_id_swaps]
      swaps = swaps_counter.is_a?(Hash) ? swaps_counter[:total].to_i : swaps_counter.to_i
      if updated > 0
        rate = (swaps.to_f / updated * 100).round(1)
        threshold = Settings::Salesforce.alert_contact_id_swap_rate_pct
        @metrics.alert!(:contact_id_swap_rate_high, value: rate, threshold: threshold) if rate > threshold
      end

      unknown = @metrics.counters[:unknown_accounts_uuids].to_i
      threshold_unknown = Settings::Salesforce.alert_unknown_uuid_count
      if unknown > threshold_unknown
        @metrics.alert!(:unknown_accounts_uuid_count, value: unknown, threshold: threshold_unknown)
      end
    end

    def log(msg)
      Rails.logger.tagged(self.class.name) { Rails.logger.info(msg) }
    end
  end
end
