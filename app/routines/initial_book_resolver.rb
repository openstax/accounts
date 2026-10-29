# Resolves the Salesforce Book__c id for the book a student signed up from,
# using the redirect URL captured in their earliest student_signed_up
# security log.
#
# The slug => Book__c map has two sources. Book__c.OSC_URL__c carries only
# first-edition slugs, and two Book__c rows can share one URL, so the CMS
# wins: it knows every book page's slug (retired and edition-suffixed ones
# included) and its salesforce_abbreviation, which equals Book__c.Name.
class InitialBookResolver
  # Matches the slug in both REX page URLs (openstax.org/books/{slug}/pages/…)
  # and book detail URLs (openstax.org/details/books/{slug}).
  BOOK_SLUG_REGEX = %r{openstax\.org/(?:details/)?books/([^/?#]+)}

  def book_id_for(user)
    # reorder: SecurityLog's default scope orders created_at desc; we want
    # the earliest signup log.
    redirect = SecurityLog.where(user: user, event_type: :student_signed_up)
                          .reorder(:created_at).first&.event_data&.[]('redirect')
    book_id_for_redirect(redirect)
  end

  def book_id_for_redirect(redirect)
    slug = redirect.to_s[BOOK_SLUG_REGEX, 1]
    return nil if slug.blank?

    book_id_by_slug[slug]
  end

  private

  # Built at most once per instance and only if some student actually has a
  # book redirect to resolve.
  def book_id_by_slug
    @book_id_by_slug ||= begin
      books = salesforce_books
      osc_book_ids_by_slug(books).merge(cms_book_ids_by_slug(books))
    end
  end

  # `all` returns an ActiveForce::ActiveQuery, which forwards only each/map/
  # inspect to its results -- not the rest of Enumerable -- so materialize it.
  def salesforce_books
    OpenStax::Salesforce::Remote::Book.all.to_a
  end

  def osc_book_ids_by_slug(books)
    books.each_with_object({}) do |book, map|
      slug = book.osc_url.to_s[BOOK_SLUG_REGEX, 1]
      map[slug] = book.id if slug.present?
    end
  end

  def cms_book_ids_by_slug(books)
    abbreviations = cms_abbreviations_by_slug
    if abbreviations.blank?
      Sentry.capture_message('[InitialBookResolver] no CMS book slugs; matching on Salesforce OSC URLs only')
      return {}
    end

    book_ids_by_name = books.sort_by(&:id).each_with_object({}) do |book, map|
      map[book.name] ||= book.id
    end

    abbreviations.each_with_object({}) do |(slug, abbreviation), map|
      book_id = book_ids_by_name[abbreviation]
      map[slug] = book_id if book_id
    end
  end

  def cms_abbreviations_by_slug
    FetchBookData.new.abbreviations_by_slug
  rescue StandardError => e
    Sentry.capture_exception(e)
    {}
  end
end
