class UpdateSchoolSalesforceInfo
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
    sheerid_school_name: :sheerid_school_name
  }

  def self.call
    new.call
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end

  def call
    check_in_id = Sentry.capture_check_in('update-school-salesforce', :in_progress)
    log('Starting UpdateSchoolSalesforceInfo')

    # Check if any Schools that have 0 users have been deleted from Salesforce and remove them
    School.where(
      'NOT EXISTS (SELECT * FROM "users" WHERE "users"."school_id" = "schools"."id")'
    ).find_in_batches(batch_size: BATCH_SIZE) do |schools|
      salesforce_ids = schools.map(&:salesforce_id)

      existing_salesforce_ids = OpenStax::Salesforce::Remote::School.select(:id).where(
        id: salesforce_ids
      ).map(&:id)

      deleted_salesforce_ids = salesforce_ids - existing_salesforce_ids

      School.where(salesforce_id: deleted_salesforce_ids).delete_all
    end

    # Go through all SF Schools and cache their information, if it changed
    schools_updated = 0
    last_id = nil
    loop do
      sf_schools = OpenStax::Salesforce::Remote::School.order(:Id).limit(BATCH_SIZE)

      sf_schools = sf_schools.where("Id > '#{last_id}'") unless last_id.nil?
      sf_schools = sf_schools.to_a
      last_id = sf_schools.last&.id

      begin
        schools_by_sf_id = School.where(
          salesforce_id: sf_schools.map(&:id)
        ).index_by(&:salesforce_id)

        schools = sf_schools.map do |sf_school|
          school = schools_by_sf_id[sf_school.id]
          schools_updated += 1 if school.nil?
          school = School.new(salesforce_id: sf_school.id) if school.nil?

          SF_TO_DB_CACHE_COLUMNS_MAP.each do |sf_column, db_column|
            school.public_send "#{db_column}=", sf_school.public_send(sf_column)
          end

          school.changed? ? school : nil
        end.compact

        School.import(
          schools, validate: false, on_duplicate_key_update: {
            conflict_target: [ :salesforce_id ], columns: SF_TO_DB_CACHE_COLUMNS_MAP.values
          }
        ) unless schools.empty?
      rescue StandardError => se
        Sentry.capture_exception se
      end

      break if sf_schools.length < BATCH_SIZE
    end

    # Loop through stale schools and update users associated with them to prevent sync issues
    School.where.not(updated_salesforce_id: nil) do |merged_school|
      # Let's make sure it wasn't just created
      if School.find_by(salesforce_id: merged_school.updated_salesforce_id)
        merged_school.update!(updated_salesforce_id: nil)
        next
      end

      # Find the new school and update the users attached to it
      sf_school = OpenStax::Salesforce::Remote::School.find_by(name: merged_school.updated_salesforce_id)
      if sf_school.nil?
        Sentry.capture_message("Possible merged school not found. Original: #{merged_school.salesforce_id} New: #{merged_school.updated_salesforce_id}")
      else
        updated_school = School.find_or_create_by(salesforce_id: sf_school.id)
        SF_TO_DB_CACHE_COLUMNS_MAP.each do |sf_column, db_column|
          updated_school.public_send "#{db_column}=", sf_school.public_send(sf_column)
        end
        updated_school.save!

        merged_school.users.update_all(school: updated_school) if merged_school.users.any?
        merged_school.destroy!
      end
    end

    log("Finished updating #{schools_updated} schools")
    Sentry.capture_check_in('update-school-salesforce', :ok, check_in_id: check_in_id)
  end
end
