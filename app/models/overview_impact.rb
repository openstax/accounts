# What the overview's "Your impact" card shows for one instructor: lifetime numbers from
# Salesforce-confirmed adoptions, how many saved books are reported this year, and
# whatever this year's reports are still waiting on confirmation.
class OverviewImpact
  CONFIRMED_ADOPTION = 'OpenStax Confirmed Adoption'.freeze

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def any_confirmed?
    adoptions.any?
  end

  def students
    @students ||= adoptions.sum { |adoption| adoption.students.to_i }
  end

  def savings
    @savings ||= adoptions.sum { |adoption| adoption.savings || 0 }
  end

  def years
    @years ||= adoptions.filter_map { |adoption| adoption.school_year.presence || adoption.school_year_label }.uniq.size
  end

  def saved_books_count
    saved_titles.size
  end

  def reported_saved_books_count
    @reported_saved_books_count ||= (saved_titles & user.titles_reported_for(school_year)).size
  end

  def school_year
    SchoolYear.current
  end

  def pending
    @pending ||= PendingImpact.new(user)
  end

  # Nothing confirmed and nothing waiting: the card invites a first report.
  def empty?
    !any_confirmed? && !pending.any?
  end

  private

  def saved_titles
    @saved_titles ||= user.user_books.includes(:book).filter_map { |saved| saved.book&.title }.uniq
  end

  def adoptions
    @adoptions ||= Adoption.where(user_id: user.id, confirmation_type: CONFIRMED_ADOPTION, rollover_status: false).to_a
  end
end
