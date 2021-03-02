class UpdateSchoolSalesforceInfo
  BATCH_SIZE = 1000

  CACHE_COLUMNS = [
    :city,
    :state,
    :type,
    :location,
    :is_kip,
    :is_child_of_kip,
    :sheerid_school_name
  ]

  def self.call
    new.call
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end

  def call
    log 'Starting'

    # Go through all SF Schools and cache their information, if it changed

    last_id = nil
    loop do
      sf_schools = OpenStax::Salesforce::Remote::School.order(:Id).limit(BATCH_SIZE)
      sf_schools = sf_schools.where("Id > '#{last_id}'") unless last_id.nil?
      sf_schools = sf_schools.to_a
      last_id = sf_schools.last.id

      begin
        schools_by_sf_id = School.where(
          salesforce_id: sf_schools.map(&:id)
        ).index_by(&:salesforce_id)

        schools = sf_schools.map do |sf_school|
          school = schools_by_sf_id[sf_school.id]
          school = School.new(salesforce_id: sf_school.id) if school.nil?

          CACHE_COLUMNS.each do |column|
            school.public_send "#{column}=", sf_school.public_send(column)
          end

          school.changed? ? school : nil
        end.compact

        School.import schools, validate: false, on_duplicate_key_update: {
          conflict_target: [ :salesforce_id ], columns: CACHE_COLUMNS
        }
      rescue StandardError => se
        Raven.capture_exception se
      end

      break if sf_schools.length < BATCH_SIZE
    end

    log 'Finished'
  end
end
