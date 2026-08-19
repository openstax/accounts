# Nightly push of students' picked schools to Salesforce Student__c records
# (Name = accounts UUID, School__c = school's Salesforce Account id).
# Pseudonymous by design: no name or email is ever sent.
class PushStudentSchoolsToSalesforce
  BATCH_SIZE = 250

  # Matches the slug in both REX page URLs (openstax.org/books/{slug}/pages/…)
  # and book detail URLs (openstax.org/details/books/{slug}).
  BOOK_SLUG_REGEX = %r{openstax\.org/(?:details/)?books/([^/?#]+)}

  def self.call
    new.call
  end

  def call
    return unless Settings::Salesforce.push_students_enabled

    User.student
        .where.not(school_id: nil)
        .where(salesforce_student_pushed_at: nil)
        .preload(:school)
        .find_each(batch_size: BATCH_SIZE) do |user|
      push(user)
    end
  end

  private

  def push(user)
    sf_school_id = user.school&.salesforce_id
    return if sf_school_id.blank?

    student = OpenStax::Salesforce::Remote::Student.where(name: user.uuid).first

    if student.nil?
      OpenStax::Salesforce::Remote::Student.new(
        name: user.uuid,
        school_id: sf_school_id,
        initial_book_id: initial_book_id_for(user)
      ).save!
    else
      # Never overwrite values already set in Salesforce: an Assignable
      # LMS-derived school beats a signup-form pick, and an already-recorded
      # initial book beats a re-derived one. Only fill in blanks.
      changed = false

      if student.school_id.blank?
        student.school_id = sf_school_id
        changed = true
      end

      if student.initial_book_id.blank? && (book_id = initial_book_id_for(user)).present?
        student.initial_book_id = book_id
        changed = true
      end

      student.save! if changed
    end

    user.update_column(:salesforce_student_pushed_at, Time.current)
  rescue StandardError => e
    Sentry.capture_exception(e)
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
    @book_id_by_slug ||= OpenStax::Salesforce::Remote::BookUrl.active_with_url
      .each_with_object({}) do |book, map|
        slug = book.osc_url.to_s[BOOK_SLUG_REGEX, 1]
        map[slug] = book.id if slug.present?
      end
  end
end
