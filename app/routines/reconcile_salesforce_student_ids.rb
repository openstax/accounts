# One-time (rerunnable) backfill matching pre-existing Student__c records to
# Accounts users by uuid, so the nightly login-date sync (which only ever
# updates users whose salesforce_student_id is already set) has something to
# write to. Not part of the cron; see lib/tasks/accounts/reconcile_salesforce_student_ids.rake.
class ReconcileSalesforceStudentIds
  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

  Stats = Struct.new(:scanned, :matched, :updated, :unmatched, :invalid_name, :duplicate_name) do
    def initialize(*)
      super
      members.each { |member| self[member] ||= 0 }
    end
  end

  def self.call
    new.call
  end

  def call
    stats = Stats.new
    seen_names = {}

    page = ActiveForce.sfdc_client.query(select_id_and_name_soql)
    page_number = 1

    loop do
      process_page(page.current_page, seen_names, stats)
      log_progress(page_number, stats)

      break unless page.has_next_page?

      page = page.next_page
      page_number += 1
    end

    Rails.logger.info("[ReconcileSalesforceStudentIds] complete: #{stats.to_h}")
    stats
  end

  private

  def select_id_and_name_soql
    OpenStax::Salesforce::Remote::Student.select(:id, :name).to_s
  end

  def process_page(records, seen_names, stats)
    stats.scanned += records.size

    names_to_sfid = names_to_sfid_for(records, seen_names, stats)
    return if names_to_sfid.empty?

    update_matching_users(names_to_sfid, stats)
  end

  def names_to_sfid_for(records, seen_names, stats)
    records.each_with_object({}) do |record, memo|
      sfid = record['Id']
      name = record['Name']

      unless name&.match?(UUID_REGEX)
        stats.invalid_name += 1
        next
      end

      if seen_names.key?(name)
        stats.duplicate_name += 1
        log_duplicate(name, seen_names[name], sfid)
        next
      end

      seen_names[name] = sfid
      memo[name] = sfid
    end
  end

  def update_matching_users(names_to_sfid, stats)
    users = User.where(uuid: names_to_sfid.keys).pluck(:id, :uuid, :salesforce_student_id)
    stats.matched += users.size
    stats.unmatched += names_to_sfid.size - users.size

    changed_ids_to_sfid = users.each_with_object({}) do |(id, uuid, current_sfid), memo|
      target_sfid = names_to_sfid[uuid]
      memo[id] = target_sfid if current_sfid != target_sfid
    end

    stats.updated += changed_ids_to_sfid.size
    bulk_update(changed_ids_to_sfid)
  end

  def bulk_update(ids_to_sfid)
    return if ids_to_sfid.empty?

    values = ids_to_sfid.map { |id, sfid| "(#{id}, #{User.connection.quote(sfid)})" }.join(',')

    User.connection.execute(<<~SQL)
      UPDATE users AS u
      SET salesforce_student_id = v.sfid
      FROM (VALUES #{values}) AS v(id, sfid)
      WHERE u.id = v.id
    SQL
  end

  def log_duplicate(name, first_sfid, second_sfid)
    Rails.logger.warn(
      "[ReconcileSalesforceStudentIds] duplicate Student__c Name=#{name}: " \
      "#{first_sfid} and #{second_sfid}"
    )
  end

  def log_progress(page_number, stats)
    Rails.logger.info(
      "[ReconcileSalesforceStudentIds] page #{page_number}: scanned=#{stats.scanned} " \
      "matched=#{stats.matched} updated=#{stats.updated} unmatched=#{stats.unmatched} " \
      "invalid_name=#{stats.invalid_name} duplicate_name=#{stats.duplicate_name}"
    )
  end
end
