# This school year's "using" reports that Salesforce hasn't confirmed yet. Confirmed adoptions
# only arrive with the nightly sync, so without this a report wouldn't change anything the
# instructor sees until the next day. A report stops being pending once a confirmed adoption
# for the same book and school year exists.
class PendingImpact
  CONFIRMED_ADOPTION = 'OpenStax Confirmed Adoption'.freeze

  attr_reader :school_year

  def initialize(user, school_year: SchoolYear.current)
    @user = user
    @school_year = school_year
  end

  def reports
    @reports ||= @user.adoption_reports.using.where(school_year: school_year)
                      .where("review_status IS NULL OR review_status <> 'rejected'").order(:book_title)
                      .reject { |report| confirmed?(report) }
  end

  def any?
    reports.any?
  end

  def students
    reports.sum { |report| report.students.to_i }
  end

  def books
    reports.size
  end

  private

  def confirmed?(report)
    confirmed_keys.any? do |book_id, name, title|
      (report.book_id && report.book_id == book_id) ||
        (report.salesforce_book_name.present? && report.salesforce_book_name == name) ||
        report.book_title == title
    end
  end

  def confirmed_keys
    @confirmed_keys ||= @user.adoptions.includes(:book)
                             .where(confirmation_type: CONFIRMED_ADOPTION, rollover_status: false)
                             .select { |adoption| (adoption.school_year.presence || adoption.school_year_label) == school_year }
                             .map { |adoption| [adoption.book&.id, adoption.book&.salesforce_name, adoption.book&.title] }
  end
end
