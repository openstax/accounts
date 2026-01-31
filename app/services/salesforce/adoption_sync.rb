module Salesforce
  class AdoptionSync
    FIELDS = %w[
      Id
      Name
      Name__c
      Adoption_Type__c
      Book__c
      Assignable_Adoption_Status__c
      Assignable_Assignments_Created_Count__c
      Assignable_First_Assignment_Created_Date__c
      Assignable_Most_Recent_Created_Date__c
      Base_Year__c
      Class_Start_Date__c
      Confirmation_Date__c
      Confirmation_Type__c
      How_Using__c
      Languages__c
      Likely_to_adopt_score__c
      Notes__c
      Related_Account__c
      Related_Contact__c
      Opportunity__c
      Rollover_Status__c
      School_Year__c
      Students__c
      Terms_Used__c
      Tracking_Parameters__c
      Savings__c
      LastModifiedDate
    ].freeze

    BATCH_SIZE = 200

    STRING_FIELDS = {
      adoption_number: 'Name',
      salesforce_name: 'Name__c',
      adoption_type: 'Adoption_Type__c',
      terms_used: 'Terms_Used__c',
      how_using: 'How_Using__c',
      confirmation_type: 'Confirmation_Type__c',
      notes: 'Notes__c',
      tracking_parameters: 'Tracking_Parameters__c',
      assignable_adoption_status: 'Assignable_Adoption_Status__c',
      school_year: 'School_Year__c'
    }.freeze

    STRING_ID_FIELDS = {
      salesforce_account_id: 'Related_Account__c',
      salesforce_contact_id: 'Related_Contact__c',
      salesforce_opportunity_id: 'Opportunity__c',
      salesforce_book_id: 'Book__c'
    }.freeze

    INTEGER_FIELDS = {
      base_year: 'Base_Year__c',
      students: 'Students__c',
      assignable_assignments_created_count: 'Assignable_Assignments_Created_Count__c',
      likely_to_adopt_score: 'Likely_to_adopt_score__c'
    }.freeze

    DATE_FIELDS = {
      class_start_date: 'Class_Start_Date__c',
      confirmation_date: 'Confirmation_Date__c',
      assignable_first_assignment_created_date: 'Assignable_First_Assignment_Created_Date__c',
      assignable_most_recent_created_date: 'Assignable_Most_Recent_Created_Date__c'
    }.freeze

    BOOLEAN_FIELDS = {
      rollover_status: 'Rollover_Status__c'
    }.freeze

    # NOTE: Manual edits to savings in Accounts can be overwritten when Salesforce
    # sends a fresh Savings__c value during the next sync.
    DECIMAL_FIELDS = {
      savings: 'Savings__c'
    }.freeze

    attr_reader :since, :limit, :logger

    def self.call(...)
      new(...).call
    end

    def initialize(since: nil, limit: nil, dry_run: false, logger: Rails.logger, client: nil)
      @since = parse_time(since)
      @limit = limit.present? ? limit.to_i : nil
      @dry_run = dry_run
      @logger = logger
      @client = client
      @stats = Hash.new(0)
      @errors = []
    end

    def call
      check_in_id = Sentry.capture_check_in('salesforce-adoption-sync', :in_progress)
      log("Starting Adoption sync#{' (dry run)' if dry_run?}")

      fetch_batches do |batch|
        process_batch(batch)
        break if limit_reached?
      end

      log("Finished Adoption sync scanned=#{@stats[:scanned]} upserted=#{@stats[:upserted]} created=#{@stats[:created]} updated=#{@stats[:updated]} school_mapped=#{@stats[:school_mapped]} user_mapped=#{@stats[:user_mapped]} book_mapped=#{@stats[:book_mapped]} errors=#{@errors.count}")
      Sentry.capture_check_in('salesforce-adoption-sync', :ok, check_in_id: check_in_id)

      { stats: @stats.dup, errors: @errors }
    rescue StandardError => e
      Sentry.capture_exception(e)
      Sentry.capture_check_in('salesforce-adoption-sync', :error, check_in_id: check_in_id) if check_in_id
      raise
    end

    private

    def dry_run?
      @dry_run
    end

    def fetch_batches
      remaining = @limit
      response = salesforce_client.query(build_query(remaining))
      yield response.to_a
      while response.next_page?
        break if limit_reached?
        response = salesforce_client.query_more(response.next_page)
        yield response.to_a
      end
    end

    def build_query(limit_value)
      clauses = []
      clauses << "LastModifiedDate >= #{since.utc.iso8601}" if since.present?
      where_sql = clauses.any? ? "WHERE #{clauses.join(' AND ')}" : ''
      limit_sql = limit_value.to_i.positive? ? "LIMIT #{limit_value.to_i}" : ''

      <<~SOQL.squish
        SELECT #{FIELDS.join(', ')}
        FROM Adoption__c
        #{where_sql}
        ORDER BY LastModifiedDate ASC
        #{limit_sql}
      SOQL
    end

    def process_batch(sf_records)
      records = Array(sf_records)
      return if records.empty?

      @stats[:scanned] += records.length
      account_ids = records.map { |record| sf_value(record, 'Related_Account__c') }.compact.uniq
      contact_ids = records.map { |record| sf_value(record, 'Related_Contact__c') }.compact.uniq

      schools_by_sf_id = School.where(salesforce_id: account_ids).index_by(&:salesforce_id)
      users_by_sf_contact_id = User.where(salesforce_contact_id: contact_ids).index_by(&:salesforce_contact_id)

      book_ids = records.map { |record| sf_value(record, 'Book__c') }.compact.uniq
      books_by_sf_id = Book.where(salesforce_book_id: book_ids).index_by(&:salesforce_book_id)

      records.each do |sf_record|
        upsert_record(sf_record, schools_by_sf_id, users_by_sf_contact_id, books_by_sf_id)
      end
    end

    def upsert_record(sf_record, schools_by_sf_id, users_by_sf_contact_id, books_by_sf_id)
      sf_id = sf_value(sf_record, 'Id')
      return if sf_id.blank?

      adoption = Adoption.find_or_initialize_by(salesforce_id: sf_id)
      created = adoption.new_record?
      attributes = build_attributes(sf_record)
      adoption.assign_attributes(attributes) unless attributes.empty?
      apply_relationships(adoption, schools_by_sf_id, users_by_sf_contact_id, books_by_sf_id)

      if dry_run?
        track_stats(created, adoption.changed?)
      elsif adoption.changed? || created
          adoption.save!
          track_stats(created, true)
      end
    rescue StandardError => e
      log("Failed to upsert adoption #{sf_id}: #{e.message}", :error)
      Sentry.capture_exception(e, extra: { salesforce_id: sf_id })
      @errors << { salesforce_id: sf_id, message: e.message }
    end

    def track_stats(created, changed)
      return unless changed || created

      @stats[:upserted] += 1
      if created
        @stats[:created] += 1
      else
        @stats[:updated] += 1
      end
    end

    def apply_relationships(adoption, schools_by_sf_id, users_by_sf_contact_id, books_by_sf_id)
      account_id = adoption.salesforce_account_id
      contact_id = adoption.salesforce_contact_id
      book_id = adoption.salesforce_book_id

      if account_id.present?
        school = schools_by_sf_id[account_id]
        if school
          adoption.school = school
          @stats[:school_mapped] += 1
        end
      else
        adoption.school = nil
      end

      if contact_id.present?
        user = users_by_sf_contact_id[contact_id]
        if user
          adoption.user = user
          @stats[:user_mapped] += 1
        end
      else
        adoption.user = nil
      end

      if book_id.present?
        book = books_by_sf_id[book_id]
        if book
          adoption.book = book
          @stats[:book_mapped] += 1
        end
      else
        adoption.book = nil
      end
    end

    def build_attributes(sf_record)
      attrs = {}

      assign_string_fields(attrs, sf_record, STRING_FIELDS)
      assign_string_fields(attrs, sf_record, STRING_ID_FIELDS, allow_nil: true)
      assign_integer_fields(attrs, sf_record, INTEGER_FIELDS)
      assign_date_fields(attrs, sf_record, DATE_FIELDS)
      assign_boolean_fields(attrs, sf_record, BOOLEAN_FIELDS)
      assign_decimal_fields(attrs, sf_record, DECIMAL_FIELDS)
      assign_languages(attrs, sf_record)

      attrs
    end

    def assign_string_fields(attrs, sf_record, mapping, allow_nil: false)
      mapping.each do |attr, field|
        value = sf_value(sf_record, field)
        if value.nil?
          attrs[attr] = nil if allow_nil
        elsif value.is_a?(String) && value.strip.empty?
          next
        else
          attrs[attr] = value
        end
      end
    end

    def assign_integer_fields(attrs, sf_record, mapping)
      mapping.each do |attr, field|
        value = sf_value(sf_record, field)
        attrs[attr] = value.present? ? value.to_i : nil
      end
    end

    def assign_date_fields(attrs, sf_record, mapping)
      mapping.each do |attr, field|
        value = sf_value(sf_record, field)
        attrs[attr] = parse_date(value)
      end
    end

    def assign_boolean_fields(attrs, sf_record, mapping)
      mapper = ActiveModel::Type::Boolean.new
      mapping.each do |attr, field|
        value = sf_value(sf_record, field)
        attrs[attr] = mapper.cast(value)
      end
    end

    def assign_decimal_fields(attrs, sf_record, mapping)
      mapping.each do |attr, field|
        value = sf_value(sf_record, field)
        next if value.blank?

        attrs[attr] = BigDecimal(value.to_s)
      end
    end

    def assign_languages(attrs, sf_record)
      raw = sf_value(sf_record, 'Languages__c')
      return if raw.nil?

      attrs[:languages] = parse_languages(raw)
    end

    def parse_languages(value)
      value.to_s.split(';').map(&:strip).reject(&:blank?)
    end

    def parse_date(value)
      return if value.blank?

      value.to_date
    rescue ArgumentError
      nil
    end

    def sf_value(record, field)
      if record.respond_to?(:[])
        record[field] || record[field.to_sym]
      elsif record.respond_to?(field)
        record.public_send(field)
      end
    end

    def salesforce_client
      @client ||= Restforce.new(
        username: salesforce_config.username,
        password: salesforce_config.password,
        security_token: salesforce_config.security_token,
        client_id: salesforce_config.consumer_key,
        client_secret: salesforce_config.consumer_secret,
        host: salesforce_config.login_domain,
        api_version: salesforce_config.api_version
      )
    end

    def salesforce_config
      @salesforce_config ||= OpenStax::Salesforce.configuration
    end

    def parse_time(value)
      return if value.blank?

      value.is_a?(Time) ? value : Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def limit_reached?
      limit.present? && @stats[:scanned] >= limit
    end

    def log(message, level = :info)
      logger.public_send(level, "[Salesforce::AdoptionSync] #{message}")
    end
  end
end
