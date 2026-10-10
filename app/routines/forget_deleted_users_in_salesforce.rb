# Nightly (cron:day) pass that tells Salesforce to forget people who deleted
# their Accounts account.
#
# Reads IndividualId from every Contact and Lead that belongs to the user --
# found by the stored salesforce_contact_id / salesforce_lead_id and by
# Accounts_UUID__c, which also reaches a Contact the old one was merged into
# and records Accounts never linked -- sets ShouldForget = true on each
# distinct Individual, and stamps users.salesforce_forgotten_at. A Salesforce
# flow does the scrubbing; this pass only raises the flag. It writes raw API
# names straight into the Composite payload, like PushUserActivityToSalesforce,
# so it doesn't depend on the gem's attribute mapping.
#
# A converted Lead has no Individual of its own (conversion clears it) and is
# scrubbed through its converted Contact, so it resolves to that Contact's.
#
# A NULL salesforce_forgotten_at means "not processed yet". A user is stamped
# when every Individual found for them was flagged, which includes finding
# nothing at all: deleted users are excluded from every push path, so no new
# record can appear later. A found record with no IndividualId, or a rejected
# Individual update, leaves the user unstamped so the next run retries.
# A stored id that no longer exists in Salesforce is unlinked, as in
# PushUserActivityToSalesforce.
class ForgetDeletedUsersInSalesforce
  BATCH_SIZE = 100
  SALESFORCE_ID_REGEX = /\A[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?\z/
  LEAD_FIELDS = 'Id, IndividualId, IsConverted, ConvertedContactId'.freeze
  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

  LINKS = {
    'Contact' => { id_column: :salesforce_contact_id, unlink_columns: PushUserActivityToSalesforce::CONTACT_UNLINK_COLUMNS },
    'Lead' => { id_column: :salesforce_lead_id, unlink_columns: %i[salesforce_lead_id] }
  }.freeze

  def self.call
    new.call
  end

  def call
    return unless Settings::Salesforce.forget_deleted_users_enabled

    @update_failures = PushUserActivityToSalesforce::FailureTally.new
    @no_individual = PushUserActivityToSalesforce::FailureTally.new

    pending_users.find_in_batches(batch_size: BATCH_SIZE) do |users|
      break unless forget_batch(users)
    end

    report('Individual update failed', @update_failures)
    report('linked record has no IndividualId', @no_individual)
  end

  private

  # Backed by index_users_deleted_pending_salesforce_forget.
  def pending_users
    User.where(is_deleted: true, salesforce_forgotten_at: nil)
  end

  # Returns false when the lookup fails: that points at Salesforce or the
  # connected app rather than at one user, so the rest of the run would only
  # repeat the same Sentry event.
  def forget_batch(users)
    individuals_by_record, individuals_by_uuid = lookup_individuals(users)
    individual_ids = (individuals_by_record.values + individuals_by_uuid.values.flat_map(&:values)).grep(String).uniq
    flagged = flag_individuals(individual_ids)

    users.each { |user| settle(user, individuals_by_record, individuals_by_uuid, flagged) }
    true
  rescue StandardError => e
    Sentry.capture_exception(e)
    false
  end

  # Returns [by_record, by_uuid]:
  #   by_record: { [object, id15] => individual_id } for the stored ids, where
  #     an id Salesforce doesn't return maps to :missing and a record without
  #     an Individual maps to nil. Keyed on 15 characters because Salesforce
  #     answers with 18-character ids whatever length we stored.
  #   by_uuid:   { lowercase uuid => { [object, id15] => individual_id_or_nil } }
  # Anything not shaped like a uuid never reaches SOQL.
  #
  # Converting a Lead clears its IndividualId, and the Salesforce flow scrubs a
  # converted Lead through its Contact, so a converted Lead resolves to its
  # ConvertedContactId's Individual. Leads are queried first so those Contact
  # ids ride along in the single Contact lookup by id: four queries a batch.
  def lookup_individuals(users)
    uuids = users.map { |user| user.uuid.to_s.downcase }.grep(UUID_REGEX).uniq
    stored = LINKS.to_h { |object, config| [object, users.filter_map { |user| user[config[:id_column]].presence }.uniq] }

    leads_by_id = query_by(
      'Lead', stored['Lead'].grep(SALESFORCE_ID_REGEX), 'Id', LEAD_FIELDS
    ) { |record| [key('Lead', record['Id']), lead_row(record)] }
    leads_by_uuid = query_by('Lead', uuids, 'Accounts_UUID__c', "#{LEAD_FIELDS}, Accounts_UUID__c") do |record|
      [[record['Accounts_UUID__c'].to_s.downcase, key('Lead', record['Id'])], lead_row(record)]
    end

    contact_ids = (stored['Contact'].grep(SALESFORCE_ID_REGEX) +
                   (leads_by_id.values + leads_by_uuid.values).grep(Hash).filter_map { |row| row[:contact_id] }).uniq
    contacts_by_id = query_by('Contact', contact_ids, 'Id', 'Id, IndividualId') do |record|
      [key('Contact', record['Id']), record['IndividualId'].presence]
    end
    contacts_by_uuid = query_by('Contact', uuids, 'Accounts_UUID__c', 'Id, IndividualId, Accounts_UUID__c') do |record|
      [[record['Accounts_UUID__c'].to_s.downcase, key('Contact', record['Id'])], record['IndividualId'].presence]
    end

    by_record = {}
    stored['Contact'].each { |id| by_record[key('Contact', id)] = contacts_by_id.fetch(key('Contact', id), :missing) }
    stored['Lead'].each do |id|
      row = leads_by_id.fetch(key('Lead', id), :missing)
      by_record[key('Lead', id)] = row == :missing ? :missing : resolve(row, contacts_by_id)
    end

    by_uuid = Hash.new { |hash, uuid| hash[uuid] = {} }
    contacts_by_uuid.each { |(uuid, record_key), individual| by_uuid[uuid][record_key] = individual }
    leads_by_uuid.each { |(uuid, record_key), row| by_uuid[uuid][record_key] = resolve(row, contacts_by_id) }

    [by_record, by_uuid]
  end

  # Yields each record of one SOQL query (skipped when there is nothing to ask
  # for) and collects the [key, value] pairs the block returns.
  def query_by(object, values, field, select_fields)
    return {} if values.empty?

    quoted = values.map { |value| "'#{value}'" }.join(',')
    ActiveForce.sfdc_client.query("SELECT #{select_fields} FROM #{object} WHERE #{field} IN (#{quoted})")
                           .to_h { |record| yield(record) }
  end

  def lead_row(record)
    { individual: record['IndividualId'].presence, converted: record['IsConverted'] == true,
      contact_id: record['ConvertedContactId'].presence }
  end

  def resolve(row, contacts_by_id)
    return row[:individual] unless row[:converted]

    contacts_by_id[key('Contact', row[:contact_id])]
  end

  def key(object, id)
    [object, id.to_s[0, 15]]
  end

  # { individual_id => true } for every Individual Salesforce accepted.
  def flag_individuals(individual_ids)
    return {} if individual_ids.empty?

    results = ActiveForce.sfdc_client.batch do |batch|
      individual_ids.each { |id| batch.update('Individual', Id: id, ShouldForget: true) }
    end

    individual_ids.zip(results).each_with_object({}) do |(id, result), flagged|
      if succeeded?(result)
        flagged[id] = true
      else
        @update_failures.add(id, result)
      end
    end
  end

  def settle(user, individuals_by_record, individuals_by_uuid, flagged)
    found = (individuals_by_uuid[user.uuid.to_s.downcase] || {}).dup

    LINKS.each do |object, config|
      record_id = user[config[:id_column]].presence
      next if record_id.nil?

      individual_id = individuals_by_record[key(object, record_id)]
      if individual_id == :missing
        unlink(user, object, config, record_id)
      else
        found[key(object, record_id)] = individual_id
      end
    end

    complete = true
    found.each do |(object, record_id), individual_id|
      if individual_id.nil?
        @no_individual.add(user.id, { object: object, salesforce_id: record_id })
        complete = false
      elsif !flagged[individual_id]
        complete = false
      end
    end

    user.update_column(:salesforce_forgotten_at, Time.current) if complete
  rescue StandardError => e
    Sentry.capture_exception(e, extra: { user_id: user.id })
  end

  # Compare-and-set on the dead id, as in PushUserActivityToSalesforce#unlink:
  # the Contact sync or a webhook may have re-linked the user in the meantime.
  def unlink(user, object, config, dead_id)
    unlinked = User.where(id: user.id, config[:id_column] => dead_id)
                   .update_all(config[:unlink_columns].index_with(nil))
    return if unlinked.zero?

    SecurityLog.create!(
      user: user,
      event_type: :salesforce_record_unlinked,
      event_data: { object: object, salesforce_id: dead_id, pass: :forget_deleted_user }
    )
  end

  def succeeded?(result)
    result.present? && result['statusCode'].to_i.between?(200, 299)
  end

  def report(what, tally)
    return if tally.empty?

    Sentry.capture_message(
      "[ForgetDeletedUsersInSalesforce] #{what} for #{tally.count} records",
      level: :warning,
      extra: { failures: tally.samples }
    )
  end
end
