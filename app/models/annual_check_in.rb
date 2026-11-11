# What the inline annual check-in card shows for one instructor: a row per
# book they might be teaching with, prefilled from last school year.
class AnnualCheckIn
  Row = Struct.new(:key, :title, :abbreviation, :students, :how_using, keyword_init: true)

  CONFIRMED_ADOPTION = 'OpenStax Confirmed Adoption'.freeze

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def school_year_label
    SchoolYear.current
  end

  # Union of saved books, last year's reports and last year's confirmed adoptions, deduped by title.
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

  # Books already marked considering or just looking this year are left out of the check-in.
  def answered_locally
    @answered_locally ||= user.adoption_reports.where(school_year: school_year_label, status: %w[considering browsing])
                              .pluck(:book_title).to_set
  end

  def last_school_year
    SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1)
  end

  def candidates
    candidates = {}

    user.user_books.includes(:book).order(:created_at).each do |user_book|
      candidates[user_book.book.title] ||= {} if user_book.book
    end

    user.adoption_reports.where(school_year: last_school_year).order(:id).each do |report|
      merge(candidates, report.book_title, abbreviation: report.salesforce_book_name,
                                           students: report.students, how_using: report.how_using)
    end

    last_year_adoptions.each do |adoption|
      title = adoption.book&.title || adoption.salesforce_name
      next if title.blank?

      how_using = adoption.how_using if AdoptionReport::HOW_USING_OPTIONS.include?(adoption.how_using)
      merge(candidates, title, students: adoption.students, how_using: how_using)
    end

    candidates.except(*answered_locally)
  end

  # A report beats an adoption, field by field.
  def merge(candidates, title, values)
    entry = (candidates[title] ||= {})
    values.each { |field, value| entry[field] = value if entry[field].nil? && value.present? }
  end

  def last_year_adoptions
    user.adoptions.includes(:book).where(confirmation_type: CONFIRMED_ADOPTION, rollover_status: false)
        .select { |adoption| (adoption.school_year.presence || adoption.school_year_label) == last_school_year }
  end

  def abbreviation_by_title
    @abbreviation_by_title ||= AdoptionBookCatalog.books.to_h { |book| [book.title, book.salesforce_abbreviation] }
  end

  def catalog_how_using
    @catalog_how_using ||= AdoptionBookCatalog.how_using_by_book_for(user)
  end
end
