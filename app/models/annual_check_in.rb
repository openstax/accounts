# What the inline check-in card shows for one instructor: a row per book they
# might be teaching with. The fall card prefills from last school year; the
# spring card (SPRING_WINDOW) prefills from this school year's own reports.
class AnnualCheckIn
  Row = Struct.new(:key, :title, :abbreviation, :students, :how_using, keyword_init: true)

  CONFIRMED_ADOPTION = 'OpenStax Confirmed Adoption'.freeze

  # The only place the spring window is defined: [month, day] pairs, both ends inclusive.
  SPRING_WINDOW = { start: [1, 2], finish: [3, 15] }.freeze

  class << self
    def spring?(date = Time.zone.today)
      today = [date.month, date.day]
      (today <=> SPRING_WINDOW[:start]) >= 0 && (today <=> SPRING_WINDOW[:finish]) <= 0
    end

    def term_on(date = Time.zone.today)
      spring?(date) ? :spring : :fall
    end

    def spring_window_start(date = Time.zone.today)
      month, day = SPRING_WINDOW[:start]
      Time.zone.local(date.year, month, day)
    end
  end

  attr_reader :user, :term

  def initialize(user, term: self.class.term_on)
    @user = user
    @term = term
  end

  def spring?
    term == :spring
  end

  # Spring wording where the spring card has its own, the fall wording otherwise.
  def copy(key, **options)
    options = { school_year: school_year_label }.merge(options)
    I18n.t("annual_check_in.#{term}.#{key}", default: :"annual_check_in.#{key}", **options)
  end

  def school_year_label
    SchoolYear.current
  end

  # Union of saved books and prior reports and confirmed adoptions, deduped by title.
  def rows
    @rows ||= candidates.each_with_index.map do |(title, last_year), index|
      abbreviation = last_year[:abbreviation] || abbreviation_by_title[title]
      Row.new(
        key: "book_#{index}",
        title: title,
        abbreviation: abbreviation,
        students: last_year[:students],
        how_using: last_year[:how_using] || catalog_how_using[abbreviation] || AdoptionReport::HOW_USING_OPTIONS.first
      )
    end
  end

  def streak_years
    @streak_years ||= user.check_in_streak_years
  end

  def streak_pending_year_label
    SchoolYear.short_label_for(SchoolYear.base_year_for(Time.zone.today))
  end

  # [lead, rest], or [nil, nil] with no prior streak. Counts the year being confirmed.
  def streak_copy
    return [nil, nil] if streak_years <= 0

    [I18n.t('annual_check_in.streak.lead', year: streak_years + 1), I18n.t('annual_check_in.streak.rest')]
  end

  # Offered instead of a streak to someone who reported before but skipped last year.
  def grace_copy
    return unless streak_years.zero? && user.adoption_reports.where.not(school_year: SchoolYear.current).exists?

    I18n.t('annual_check_in.streak.grace')
  end

  private

  # Fall leaves out books already marked considering or just looking this year. Spring leaves out
  # every book answered this year except the ones reported as in use, which are the rows to review.
  def answered_locally
    @answered_locally ||=
      if spring?
        user.titles_answered_for(school_year_label) - user.titles_reported_for(school_year_label)
      else
        user.adoption_reports.where(school_year: school_year_label, status: %w[considering browsing])
            .pluck(:book_title)
      end.to_set
  end

  def last_school_year
    SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1)
  end

  def candidates
    candidates = {}

    merge_year(candidates, school_year_label, using_only: true) if spring?

    user.user_books.includes(:book).order(:created_at).each do |user_book|
      candidates[user_book.book.title] ||= {} if user_book.book
    end

    merge_year(candidates, last_school_year) unless spring? && candidates.any? { |_, values| values.present? }

    candidates.except(*answered_locally)
  end

  def merge_year(candidates, school_year, using_only: false)
    reports = user.adoption_reports.where(school_year: school_year).order(:id)
    reports = reports.using if using_only
    reports.each do |report|
      merge(candidates, report.book_title, abbreviation: report.salesforce_book_name,
                                           students: report.students, how_using: report.how_using)
    end

    adoptions_for(school_year).each do |adoption|
      title = adoption.book&.title || adoption.salesforce_name
      next if title.blank?

      how_using = adoption.how_using if AdoptionReport::HOW_USING_OPTIONS.include?(adoption.how_using)
      merge(candidates, title, students: adoption.students, how_using: how_using)
    end
  end

  # A report beats an adoption, field by field.
  def merge(candidates, title, values)
    entry = (candidates[title] ||= {})
    values.each { |field, value| entry[field] = value if entry[field].nil? && value.present? }
  end

  def adoptions_for(school_year)
    user.adoptions.includes(:book).where(confirmation_type: CONFIRMED_ADOPTION, rollover_status: false)
        .select { |adoption| (adoption.school_year.presence || adoption.school_year_label) == school_year }
  end

  def abbreviation_by_title
    @abbreviation_by_title ||= AdoptionBookCatalog.books.to_h { |book| [book.title, book.salesforce_abbreviation] }
  end

  def catalog_how_using
    @catalog_how_using ||= AdoptionBookCatalog.how_using_by_book_for(user)
  end
end
