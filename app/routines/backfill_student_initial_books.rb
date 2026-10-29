# One-time (rerunnable) backfill of Student__c.Initial_Book__c for students
# the nightly sync already linked, using the same signup-redirect matching as
# PushUserActivityToSalesforce. Never overwrites a value already in Salesforce.
# See lib/tasks/accounts/backfill_student_initial_books.rake.
class BackfillStudentInitialBooks
  USER_BATCH_SIZE = 1000
  LOOKUP_CHUNK_SIZE = 200
  WRITE_BATCH_SIZE = 25
  MAX_REPORTED_FAILURES = 20
  SALESFORCE_ID_REGEX = /\A[a-zA-Z0-9]{15,18}\z/

  Stats = Struct.new(:candidates, :resolvable, :already_set_or_missing, :updated, :failures, :by_book) do
    def initialize(*)
      super
      members.each { |member| self[member] ||= 0 unless member == :by_book }
      self.by_book ||= Hash.new(0)
    end
  end

  def self.call(dry_run: false)
    new(dry_run: dry_run).call
  end

  def initialize(dry_run: false)
    @dry_run = dry_run
    @resolver = InitialBookResolver.new
    @stats = Stats.new
    @failure_samples = []
  end

  def call
    User.where.not(salesforce_student_id: nil).find_in_batches(batch_size: USER_BATCH_SIZE) do |users|
      process_users(users)
    end

    report_failures
    stats
  end

  private

  attr_reader :dry_run, :resolver, :stats

  def process_users(users)
    redirects = earliest_redirects(users.map(&:id))
    stats.candidates += redirects.size

    book_ids_by_student_id = users.each_with_object({}) do |user, map|
      next unless redirects.key?(user.id) && user.salesforce_student_id.match?(SALESFORCE_ID_REGEX)

      book_id = resolver.book_id_for_redirect(redirects[user.id])
      map[user.salesforce_student_id] = book_id if book_id
    end
    stats.resolvable += book_ids_by_student_id.size

    book_ids_by_student_id.each_slice(LOOKUP_CHUNK_SIZE) { |chunk| process_chunk(chunk.to_h) }
  end

  def earliest_redirects(user_ids)
    # reorder: SecurityLog's default scope orders created_at desc.
    SecurityLog.where(user_id: user_ids, event_type: :student_signed_up)
               .reorder(:created_at)
               .pluck(:user_id, :event_data)
               .each_with_object({}) { |(user_id, data), map| map[user_id] ||= data&.[]('redirect') }
  end

  def process_chunk(book_ids_by_student_id)
    unset_ids = unset_student_ids(book_ids_by_student_id.keys)
    stats.already_set_or_missing += book_ids_by_student_id.size - unset_ids.size
    updates = book_ids_by_student_id.slice(*unset_ids)

    if dry_run
      updates.each_value { |book_id| stats.by_book[book_id] += 1 }
    else
      updates.each_slice(WRITE_BATCH_SIZE) { |batch| write_batch(batch) }
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    stats.failures += book_ids_by_student_id.size
  end

  def unset_student_ids(student_ids)
    soql = "SELECT Id FROM Student__c WHERE Initial_Book__c = null AND Id IN ('#{student_ids.join("','")}')"
    OpenStax::Salesforce::Remote::Student.sfdc_client.query(soql).map { |record| record['Id'] }
  end

  def write_batch(batch)
    results = OpenStax::Salesforce::Remote::Student.sfdc_client.batch do |requests|
      batch.each do |student_id, book_id|
        requests.update('Student__c', Id: student_id, Initial_Book__c: book_id)
      end
    end

    batch.zip(results).each do |(student_id, book_id), result|
      if result.present? && result['statusCode'].to_i.between?(200, 299)
        stats.updated += 1
        stats.by_book[book_id] += 1
      else
        stats.failures += 1
        @failure_samples << { student_id: student_id, result: result } if @failure_samples.size < MAX_REPORTED_FAILURES
      end
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    stats.failures += batch.size
  end

  def report_failures
    return if @failure_samples.empty?

    Sentry.capture_message(
      "[BackfillStudentInitialBooks] #{stats.failures} Student__c updates failed",
      level: :warning,
      extra: { failures: @failure_samples }
    )
  end
end
