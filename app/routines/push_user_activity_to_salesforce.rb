# Nightly sync of students' picked schools and both students' and
# instructors' login/last-seen activity to Salesforce. Pseudonymous by
# design: no name or email is ever sent.
#
# Four bounded passes, each backed by its own partial index and gated by
# its own feature flag:
#   1. link/create -- runs once per student. Resolves or creates the
#      Student__c (Name = accounts UUID, School__c = school's Salesforce
#      Account id, Last_Account_Login_Date__c = most recent login), stamps its
#      Salesforce id onto the user, and records the first known login date.
#   2. student login refresh -- recurring. Updates only
#      Last_Account_Login_Date__c on students already linked, straight from the
#      stored Salesforce id, with no SOQL lookup. Never creates a Student__c:
#      a student who never finishes pass 1 must not gain a record whose only
#      content is a login date.
#   3. instructor login refresh -- recurring. Same as pass 2 but for
#      instructors' Contact records, keyed by the salesforce_contact_id
#      already linked elsewhere (lead conversion, profile sync). Never
#      creates or otherwise touches a Contact -- Last_Account_Login_Date__c is
#      the only field Accounts is allowed to write there.
#   4. last-seen refresh -- recurring, both populations under one flag.
#      Writes Last_Website_Visit__c, creating nothing, like passes 2 and 3.
#      Its halves stamp separate columns because one user can hold both
#      links: an educator who switches to the student role keeps the Contact
#      their lead converted into, and a shared column would let the student
#      half suppress the Contact half.
class PushUserActivityToSalesforce
  BATCH_SIZE = 250
  LOOKUP_CHUNK_SIZE = 200

  # Matches the slug in both REX page URLs (openstax.org/books/{slug}/pages/…)
  # and book detail URLs (openstax.org/details/books/{slug}).
  BOOK_SLUG_REGEX = %r{openstax\.org/(?:details/)?books/([^/?#]+)}

  def self.call
    new.call
  end

  def call
    if Settings::Salesforce.push_students_enabled
      link_and_create_students
      sync_student_login_dates
    end

    sync_contact_login_dates if Settings::Salesforce.push_contact_logins_enabled

    if Settings::Salesforce.push_last_seen_enabled
      # push_students_enabled stays the single kill switch for all Student__c
      # writes, as it is for passes 1 and 2.
      sync_student_last_seen_dates if Settings::Salesforce.push_students_enabled
      sync_contact_last_seen_dates
    end
  end

  private

  def link_and_create_students
    User.student
        .where.not(school_id: nil)
        .where(salesforce_student_pushed_at: nil)
        .preload(:school)
        .find_in_batches(batch_size: BATCH_SIZE) do |users|
      linkable_users = users.select { |user| user.school&.salesforce_id.present? }

      begin
        students_by_uuid = fetch_students_by_uuid(linkable_users.map(&:uuid))
      rescue StandardError => e
        # The lookup covers the whole chunk, so a failure here can't be
        # pinned to one student -- leave the chunk unstamped for a retry
        # rather than risk creating duplicates on an unresolved lookup.
        Sentry.capture_exception(e)
        next
      end

      linkable_users.each { |user| link_or_create(user, students_by_uuid[user.uuid]) }
    end
  end

  # One SOQL query per chunk of uuids instead of one per student.
  def fetch_students_by_uuid(uuids)
    return {} if uuids.empty?

    uuids.each_slice(LOOKUP_CHUNK_SIZE).each_with_object({}) do |chunk, map|
      OpenStax::Salesforce::Remote::Student.where(name: chunk).each do |student|
        map[student.name] = student
      end
    end
  end

  def link_or_create(user, student)
    sf_school_id = user.school.salesforce_id
    login = login_date(user)

    if student.nil?
      student = OpenStax::Salesforce::Remote::Student.new(
        name: user.uuid,
        school_id: sf_school_id,
        initial_book_id: initial_book_id_for(user),
        last_account_login_date: login
      )
      student.save!
    else
      # Never overwrite values already set in Salesforce: an Assignable
      # LMS-derived school beats a signup-form pick, and an already-recorded
      # initial book beats a re-derived one. Only fill in blanks. The login
      # date isn't subject to that rule -- it always reflects our own record.
      changed = false

      if student.school_id.blank?
        student.school_id = sf_school_id
        changed = true
      end

      if student.initial_book_id.blank? && (book_id = initial_book_id_for(user)).present?
        student.initial_book_id = book_id
        changed = true
      end

      if login.present?
        student.last_account_login_date = login
        changed = true
      end

      student.save! if changed
    end

    user.update_columns(salesforce_student_id: student.id, salesforce_student_pushed_at: Time.current)
  rescue StandardError => e
    Sentry.capture_exception(e)
  end

  # A NULL salesforce_student_pushed_at means the link came from
  # ReconcileSalesforceStudentIds rather than from pass 1, so it has to
  # count as "never sent" -- comparing against it would return NULL and
  # silently exclude every reconciled student forever.
  def sync_student_login_dates
    User.student
        .where.not(salesforce_student_id: nil)
        .where.not(last_signed_in_at: nil)
        .where(
          'salesforce_student_pushed_at IS NULL OR last_signed_in_at > salesforce_student_pushed_at'
        )
        .find_in_batches(batch_size: BATCH_SIZE) do |users|
      push_student_login_dates(users)
    end
  end

  # One composite/batch request per 25 students instead of one update per
  # student -- this pass only ever touches already-linked students, so there
  # is no lookup to batch, just the writes.
  # Stamps the last_signed_in_at that was sent, not Time.current: a login
  # landing mid-batch would otherwise sit under a newer watermark and never
  # be sent. Pass 1 keeps Time.current -- its login date can be nil, and a
  # nil stamp would re-select the user for linking forever.
  def push_student_login_dates(users)
    results = OpenStax::Salesforce::Remote::Student.sfdc_client.batch do |batch|
      users.each do |user|
        batch.update(
          'Student__c',
          Id: user.salesforce_student_id,
          Last_Account_Login_Date__c: login_date(user)
        )
      end
    end

    users.zip(results).each do |user, result|
      if batch_update_succeeded?(result)
        user.update_column(:salesforce_student_pushed_at, user.last_signed_in_at)
      else
        Sentry.capture_message(
          "[PushUserActivityToSalesforce] student login-date update failed for user #{user.id}: #{result.inspect}",
          level: :warning
        )
      end
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
  end

  # Same NULL reasoning as sync_student_login_dates: salesforce_contact_id is
  # populated by lead conversion and profile-completion code paths that never
  # stamp salesforce_contact_login_pushed_at, so those instructors must count
  # as "never sent" too.
  def sync_contact_login_dates
    User.where.not(salesforce_contact_id: nil)
        .where.not(last_signed_in_at: nil)
        .where(
          'salesforce_contact_login_pushed_at IS NULL OR last_signed_in_at > salesforce_contact_login_pushed_at'
        )
        .find_in_batches(batch_size: BATCH_SIZE) do |users|
      push_contact_login_dates(users)
    end
  end

  # Only Last_Account_Login_Date__c -- never FV_Status__c, Adoption_Status__c,
  # name or school, which belong to Customer Experience once a Contact
  # exists.
  # Watermark caveat as in push_student_login_dates.
  def push_contact_login_dates(users)
    results = OpenStax::Salesforce::Remote::Contact.sfdc_client.batch do |batch|
      users.each do |user|
        batch.update(
          'Contact',
          Id: user.salesforce_contact_id,
          Last_Account_Login_Date__c: login_date(user)
        )
      end
    end

    users.zip(results).each do |user, result|
      if batch_update_succeeded?(result)
        user.update_column(:salesforce_contact_login_pushed_at, user.last_signed_in_at)
      else
        Sentry.capture_message(
          "[PushUserActivityToSalesforce] contact login-date update failed for user #{user.id}: #{result.inspect}",
          level: :warning
        )
      end
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
  end

  # Same NULL reasoning as sync_student_login_dates.
  def sync_student_last_seen_dates
    User.student
        .where.not(salesforce_student_id: nil)
        .where.not(last_seen_at: nil)
        .where(
          'salesforce_student_last_seen_pushed_at IS NULL OR ' \
          'last_seen_at > salesforce_student_last_seen_pushed_at'
        )
        .find_in_batches(batch_size: BATCH_SIZE) do |users|
      push_student_last_seen_dates(users)
    end
  end

  # Stamps the last_seen_at that was sent, not Time.current: a visit landing
  # mid-batch would otherwise sit under a newer watermark and never be sent.
  def push_student_last_seen_dates(users)
    results = OpenStax::Salesforce::Remote::Student.sfdc_client.batch do |batch|
      users.each do |user|
        batch.update(
          'Student__c',
          Id: user.salesforce_student_id,
          Last_Website_Visit__c: last_seen_date(user)
        )
      end
    end

    users.zip(results).each do |user, result|
      if batch_update_succeeded?(result)
        user.update_column(:salesforce_student_last_seen_pushed_at, user.last_seen_at)
      else
        Sentry.capture_message(
          "[PushUserActivityToSalesforce] student last-seen update failed for user #{user.id}: #{result.inspect}",
          level: :warning
        )
      end
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
  end

  # Same NULL reasoning as sync_contact_login_dates.
  def sync_contact_last_seen_dates
    User.where.not(salesforce_contact_id: nil)
        .where.not(last_seen_at: nil)
        .where(
          'salesforce_contact_last_seen_pushed_at IS NULL OR ' \
          'last_seen_at > salesforce_contact_last_seen_pushed_at'
        )
        .find_in_batches(batch_size: BATCH_SIZE) do |users|
      push_contact_last_seen_dates(users)
    end
  end

  # Watermark caveat as in push_student_last_seen_dates.
  def push_contact_last_seen_dates(users)
    results = OpenStax::Salesforce::Remote::Contact.sfdc_client.batch do |batch|
      users.each do |user|
        batch.update(
          'Contact',
          Id: user.salesforce_contact_id,
          Last_Website_Visit__c: last_seen_date(user)
        )
      end
    end

    users.zip(results).each do |user, result|
      if batch_update_succeeded?(result)
        user.update_column(:salesforce_contact_last_seen_pushed_at, user.last_seen_at)
      else
        Sentry.capture_message(
          "[PushUserActivityToSalesforce] contact last-seen update failed for user #{user.id}: #{result.inspect}",
          level: :warning
        )
      end
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
  end

  def batch_update_succeeded?(result)
    result.present? && result['statusCode'].to_i.between?(200, 299)
  end

  def login_date(user)
    return if user.last_signed_in_at.blank?

    # A fixed zone, not the server's local time, so the date doesn't drift
    # with where this runs.
    user.last_signed_in_at.utc.strftime('%Y-%m-%d')
  end

  def last_seen_date(user)
    return if user.last_seen_at.blank?

    user.last_seen_at.utc.strftime('%Y-%m-%d')
  end

  # The Salesforce Book__c id for the book whose page the student came from
  # when signing up, resolved from the redirect URL captured in the
  # student_signed_up security log. Nil when unknown or unresolvable.
  def initial_book_id_for(user)
    # reorder: SecurityLog's default scope orders created_at desc; we want
    # the earliest signup log.
    redirect = SecurityLog.where(user: user, event_type: :student_signed_up)
                          .reorder(:created_at).first&.event_data&.[]('redirect')
    slug = redirect.to_s[BOOK_SLUG_REGEX, 1]
    return nil if slug.blank?

    book_id_by_slug[slug]
  end

  # Slug => Book__c id map, queried from Salesforce at most once per call
  # and only if some student actually has a book redirect to resolve.
  def book_id_by_slug
    @book_id_by_slug ||= OpenStax::Salesforce::Remote::Book.where('OSC_URL__c != null')
      .each_with_object({}) do |book, map|
        slug = book.osc_url.to_s[BOOK_SLUG_REGEX, 1]
        map[slug] = book.id if slug.present?
      end
  end
end
