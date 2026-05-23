module Salesforce
  # Caches Salesforce Account (School) records into the local schools table.
  # Logic moved verbatim from UpdateSchoolSalesforceInfo; wrapped with
  # Salesforce::Metrics for per-run Sentry check-ins.
  class SyncSchools
    SLUG = 'update-school-salesforce'.freeze
    BATCH_SIZE = 250

    SF_TO_DB_CACHE_COLUMNS_MAP = {
      id: :salesforce_id,
      name: :name,
      city: :city,
      state: :state,
      country: :country,
      type: :type,
      school_location: :location,
      is_kip: :is_kip,
      is_child_of_kip: :is_child_of_kip,
      sheerid_school_name: :sheerid_school_name,
      has_assignable_contacts: :has_assignable_contacts
    }.freeze

    def self.call
      new.call
    end

    def call
      metrics = Metrics.new(run: 'sync_schools', slug: SLUG)
      metrics.start!
      log 'Starting SyncSchools'

      remove_deleted_schools
      schools_updated = upsert_schools_from_sf

      metrics.increment(:schools_updated, by: schools_updated)
      metrics.emit(status: :ok)
      log "Finished updating #{schools_updated} schools"
    rescue StandardError => e
      Sentry.capture_exception(e)
      metrics.emit(status: :error, extra: { error: e.class.name, message: e.message })
      raise
    end

    private

    def remove_deleted_schools
      School.where(
        'NOT EXISTS (SELECT * FROM "users" WHERE "users"."school_id" = "schools"."id")'
      ).find_in_batches(batch_size: BATCH_SIZE) do |schools|
        salesforce_ids = schools.map(&:salesforce_id)
        existing_salesforce_ids = Salesforce::Records::School.select(:id).where(id: salesforce_ids).map(&:id)
        deleted_salesforce_ids = salesforce_ids - existing_salesforce_ids
        School.where(salesforce_id: deleted_salesforce_ids).delete_all
      end
    end

    def upsert_schools_from_sf
      schools_updated = 0
      last_id = nil

      loop do
        sf_schools = Salesforce::Records::School.order(:Id).limit(BATCH_SIZE)
        sf_schools = sf_schools.where("Id > '#{last_id}'") unless last_id.nil?
        sf_schools = sf_schools.to_a
        last_id = sf_schools.last&.id

        begin
          schools_by_sf_id = School.where(salesforce_id: sf_schools.map(&:id)).index_by(&:salesforce_id)

          schools = sf_schools.map do |sf_school|
            school = schools_by_sf_id[sf_school.id]
            schools_updated += 1 if school.nil?
            school = School.new(salesforce_id: sf_school.id) if school.nil?

            SF_TO_DB_CACHE_COLUMNS_MAP.each do |sf_col, db_col|
              school.public_send("#{db_col}=", sf_school.public_send(sf_col))
            end

            school.changed? ? school : nil
          end.compact

          School.import(
            schools, validate: false,
            on_duplicate_key_update: { conflict_target: [:salesforce_id], columns: SF_TO_DB_CACHE_COLUMNS_MAP.values }
          ) unless schools.empty?
        rescue StandardError => se
          Sentry.capture_exception(se)
        end

        break if sf_schools.length < BATCH_SIZE
      end

      schools_updated
    end

    def log(msg)
      Rails.logger.tagged(self.class.name) { Rails.logger.info(msg) }
    end
  end
end
