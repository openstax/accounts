# Computes the term choices for the "Add your instructor" fallback form's
# term <select> — the soonest few terms a student could currently be
# enrolling in, plus a year-long option for the academic year they fall in.
# Mirrors SchoolYear's month-based academic-year logic (Aug start).
class TermOptions
  # (label, start month), in the order a school year progresses.
  SEASONS = [['Fall', 8], ['Spring', 1], ['Summer', 6]].freeze

  class << self
    def upcoming(date = Time.zone.today, count: 3)
      terms = candidate_terms(date, count)
      return [] if terms.empty?

      labels = terms.map { |_start_date, year, name| "#{name} #{year}" }
      labels << year_long_label(terms.first)
      labels
    end

    private

    def candidate_terms(date, count)
      cutoff = Date.new(date.year, date.month, 1)

      candidates = (date.year - 1..date.year + 2).flat_map do |year|
        SEASONS.map { |name, month| [Date.new(year, month, 1), year, name] }
      end

      candidates.select { |start_date, _year, _name| start_date >= cutoff }
                .sort_by { |start_date, _year, _name| start_date }
                .first(count)
    end

    def year_long_label(first_term)
      _start_date, year, name = first_term
      academic_year_start = name == 'Fall' ? year : year - 1

      "Year-long #{academic_year_start}–#{(academic_year_start + 1).to_s[-2, 2]}"
    end
  end
end
