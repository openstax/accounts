class UpdateSchoolSalesforceInfo
  BATCH_SIZE = 250
  SALESFORCE_ID_REGEX = /\A[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?\z/
  MAX_MERGE_CHAIN_DEPTH = 10

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

    reconcile_schools_with_users

    log("Finished updating #{schools_updated} schools")
    Sentry.capture_check_in('update-school-salesforce', :ok, check_in_id: check_in_id)
  end

  private

  # The sweeps above only see Accounts that still exist in Salesforce, so a
  # school whose Account was merged away or deleted keeps its stale
  # salesforce_id forever once users reference it, and lead saves for those
  # users fail with INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY. Repoint
  # users to the merge winner while Salesforce still remembers it, otherwise
  # detach them so the 'Find Me A Home' fallback applies at lead time.
  def reconcile_schools_with_users
    School.where(
      'EXISTS (SELECT * FROM "users" WHERE "users"."school_id" = "schools"."id")'
    ).find_in_batches(batch_size: BATCH_SIZE) do |schools|
      salesforce_ids = schools.map(&:salesforce_id)

      existing_salesforce_ids = OpenStax::Salesforce::Remote::School.select(:id).where(
        id: salesforce_ids
      ).map(&:id)

      stale_schools = schools.reject do |school|
        existing_salesforce_ids.include?(school.salesforce_id)
      end

      # A whole batch vanishing from Salesforce means an API anomaly, not mass merges
      if stale_schools.length == schools.length && schools.length >= 10
        Sentry.capture_message(
          '[UpdateSchoolSalesforceInfo] every school in a batch is missing from Salesforce; skipping reconciliation',
          level: :warning
        )
        next
      end

      stale_schools.each { |school| reconcile_stale_school(school) }
    end
  rescue StandardError => se
    Sentry.capture_exception se
  end

  def reconcile_stale_school(school)
    winner_salesforce_id = merge_winner_salesforce_id(school.salesforce_id)

    # The existence sweep and the queryAll lookup can disagree (transient API
    # inconsistency, or the Account was undeleted in between); a school whose
    # Account turns out to still exist is not stale, so leave it alone.
    if winner_salesforce_id == school.salesforce_id
      log("Salesforce account #{school.salesforce_id} appears to exist; skipping reconciliation for school #{school.id}", :warn)
      return
    end

    winner = School.find_by(salesforce_id: winner_salesforce_id) unless winner_salesforce_id.nil?

    if winner
      users_moved = User.where(school_id: school.id).update_all(school_id: winner.id)
      school.delete
      log("Moved #{users_moved} users from merged school #{school.salesforce_id} to #{winner.salesforce_id}")
    elsif winner_salesforce_id
      # The winner exists in Salesforce but the sweep hasn't cached it locally
      # yet; leave the stale school for the next run to reconcile.
      log("Merge winner #{winner_salesforce_id} for school #{school.salesforce_id} is not cached locally yet", :warn)
    else
      users_detached = User.where(school_id: school.id).update_all(school_id: nil)
      school.delete
      Sentry.capture_message(
        '[UpdateSchoolSalesforceInfo] school missing from Salesforce with no merge winner; detached its users',
        level: :warning,
        extra: {
          school_id: school.id,
          salesforce_id: school.salesforce_id,
          school_name: school.name,
          users_detached: users_detached
        }
      )
    end
  end

  # A merged Account is soft-deleted with MasterRecordId pointing at the
  # winner, which can itself have been merged later, so follow the chain to a
  # live Account using queryAll (includes recycle-bin rows). Returns nil when
  # the trail is gone (recycle bin purged, or deleted without a merge).
  def merge_winner_salesforce_id(salesforce_id)
    current_id = salesforce_id
    MAX_MERGE_CHAIN_DEPTH.times do
      return nil unless SALESFORCE_ID_REGEX.match?(current_id.to_s)

      account = ActiveForce.sfdc_client.query_all(
        "SELECT Id, IsDeleted, MasterRecordId FROM Account WHERE Id = '#{current_id}'"
      ).first

      return nil if account.nil?
      return current_id unless account['IsDeleted']

      current_id = account['MasterRecordId']
    end
    nil
  end
end
