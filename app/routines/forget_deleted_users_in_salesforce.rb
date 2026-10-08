# Nightly (cron:day) pass that tells Salesforce to forget people who deleted
# their Accounts account.
#
# Reads IndividualId from the user's linked Contact and Lead (a Lead and its
# converted Contact share one Individual), sets ShouldForget = true on each
# distinct Individual, and stamps users.salesforce_forgotten_at. A Salesforce
# flow does the scrubbing; this pass only raises the flag. It writes raw API
# names straight into the Composite payload, like PushUserActivityToSalesforce,
# so it doesn't depend on the gem's attribute mapping.
#
# A NULL salesforce_forgotten_at means "never sent". A user is stamped only
# when every record still linked to them yielded an Individual that was
# flagged; anything less leaves them unstamped, so the next run retries.
# A Contact or Lead that no longer exists in Salesforce is unlinked, as in
# PushUserActivityToSalesforce, so it can't be retried forever.
class ForgetDeletedUsersInSalesforce
  BATCH_SIZE = 100
  SALESFORCE_ID_REGEX = /\A[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?\z/

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
        .where('salesforce_contact_id IS NOT NULL OR salesforce_lead_id IS NOT NULL')
  end

  # Returns false when the lookup fails: that points at Salesforce or the
  # connected app rather than at one user, so the rest of the run would only
  # repeat the same Sentry event.
  def forget_batch(users)
    individuals_by_record = fetch_individuals(users)
    individual_ids = individuals_by_record.values.grep(String).uniq
    flagged = flag_individuals(individual_ids)

    users.each { |user| settle(user, individuals_by_record, flagged) }
    true
  rescue StandardError => e
    Sentry.capture_exception(e)
    false
  end

  # { [object, id15] => individual_id }, where an id Salesforce doesn't return
  # maps to :missing and a record without an Individual maps to nil. Keyed on
  # the 15-character prefix because Salesforce answers with 18-character ids
  # whatever length we stored.
  def fetch_individuals(users)
    LINKS.each_with_object({}) do |(object, config), map|
      ids = users.filter_map { |user| user[config[:id_column]].presence }.uniq
      next if ids.empty?

      ids.each { |id| map[key(object, id)] = :missing }

      valid_ids = ids.grep(SALESFORCE_ID_REGEX)
      next if valid_ids.empty?

      soql = "SELECT Id, IndividualId FROM #{object} WHERE Id IN (#{valid_ids.map { |id| "'#{id}'" }.join(',')})"
      ActiveForce.sfdc_client.query(soql).each do |record|
        map[key(object, record['Id'])] = record['IndividualId'].presence
      end
    end
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

  def settle(user, individuals_by_record, flagged)
    flagged_ids = []
    complete = true

    LINKS.each do |object, config|
      record_id = user[config[:id_column]].presence
      next if record_id.nil?

      individual_id = individuals_by_record[key(object, record_id)]

      if individual_id == :missing
        unlink(user, object, config, record_id)
      elsif individual_id.nil?
        @no_individual.add(user.id, { object: object, salesforce_id: record_id })
        complete = false
      elsif flagged[individual_id]
        flagged_ids << individual_id
      else
        complete = false
      end
    end

    # A user whose every record vanished has nothing left to forget; stamping
    # them would claim a flag that was never raised.
    user.update_column(:salesforce_forgotten_at, Time.current) if complete && flagged_ids.any?
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
