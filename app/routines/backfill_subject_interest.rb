# One-time (rerunnable) backfill of users.which_books from Salesforce's
# Subject_Interest__c, so existing values show up on the Books tab without
# waiting for a Contact or Lead to change. Applies the same rules as the syncs
# (UpdateUserContactInfo / UpdateUserLeadInfo): a Contact is the source and a
# blank one clears the list; a Lead only fills in or changes a non-blank value
# and is ignored once the user has a Contact. Converted Leads are skipped; the
# Contact sync reaches their Contact. See lib/tasks/accounts/backfill_subject_interest.rake.
class BackfillSubjectInterest
  BATCH_SIZE = 200

  Stats = Struct.new(:scanned, :updated, :unchanged, :missing, :lead_skipped, keyword_init: true) do
    def initialize(**)
      super
      members.each { |member| self[member] ||= 0 }
    end
  end

  def self.call(dry_run: false)
    new(dry_run: dry_run).call
  end

  def initialize(dry_run: false)
    @dry_run = dry_run
    @stats = Stats.new
  end

  def call
    sweep(User.where.not(salesforce_contact_id: [nil, '']), :salesforce_contact_id,
          OpenStax::Salesforce::Remote::Contact, lead: false)
    sweep(User.where(salesforce_contact_id: [nil, '']).where.not(salesforce_lead_id: [nil, '']), :salesforce_lead_id,
          OpenStax::Salesforce::Remote::Lead, lead: true)

    Rails.logger.info("[BackfillSubjectInterest] dry_run=#{@dry_run} #{@stats.to_h}")
    @stats
  end

  private

  def sweep(users, id_column, remote_class, lead:)
    users.find_in_batches(batch_size: BATCH_SIZE) do |batch|
      ids = batch.map { |user| user[id_column] }
      fields = lead ? %i[id subject_interest is_converted] : %i[id subject_interest]
      records = remote_class.select(*fields).where(id: ids).to_a.index_by(&:id)

      batch.each { |user| apply(user, records[user[id_column]], lead) }
    end
  end

  def apply(user, record, lead)
    @stats.scanned += 1
    return @stats.missing += 1 if record.nil?
    return @stats.lead_skipped += 1 if lead && record.is_converted

    books = BookInterest.join(record.subject_interest)
    return @stats.unchanged += 1 if (lead && books.blank?) || books == user.which_books.to_s

    BookInterest.set_user!(user, books) unless @dry_run
    @stats.updated += 1
  end
end
