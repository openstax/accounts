# Derives the Impact tab's milestone ladder (earned tiles + "next milestone"
# progress bar) purely from Adoption data already reported/confirmed --
# nothing new to build server-side, per the design notes.
#
# "Earned" tiles are always: first adoption (pinned, since it never
# recedes), plus your current standing on the two independent axes we
# track (highest student-count threshold reached, highest savings
# threshold reached) -- so the grid never shows a smaller number sitting
# next to a bigger one it's already superseded.
#
# Usage:
#   ImpactMilestones.for(lifetime_adoptions)
#   # => { earned: [Milestone, ...], next: Milestone or nil,
#   #      students: Integer, savings: BigDecimal }
class ImpactMilestones
  Milestone = Struct.new(:key, :label, :year, :unit, :value, keyword_init: true)

  # The "next milestone" progress bar always tracks student reach -- the
  # instructor-facing headline number. Savings/first-adoption milestones
  # still appear among the earned tiles, based on their own thresholds.
  STUDENT_THRESHOLDS = [100, 500, 1_000, 2_500].freeze
  SAVINGS_THRESHOLDS = [10_000, 25_000, 50_000, 100_000].freeze

  def self.for(adoptions)
    new(adoptions).call
  end

  def initialize(adoptions)
    @adoptions = adoptions.to_a.select { |adoption| adoption.school_year_start.present? }
  end

  def call
    return nil if @adoptions.empty?

    compute_running_totals

    {
      earned: earned_milestones,
      next: next_student_milestone,
      students: @total_students,
      savings: @total_savings
    }
  end

  private

  def compute_running_totals
    by_year = @adoptions.group_by(&:school_year_start).sort_by { |year, _| year }

    @total_students = 0
    @total_savings = BigDecimal('0')
    @student_crossing_year = {}
    @savings_crossing_year = {}

    by_year.each do |year, year_adoptions|
      @total_students += year_adoptions.sum { |adoption| adoption.students.to_i }
      @total_savings += year_adoptions.sum { |adoption| adoption.savings || BigDecimal('0') }

      STUDENT_THRESHOLDS.each do |threshold|
        @student_crossing_year[threshold] ||= year if @total_students >= threshold
      end

      SAVINGS_THRESHOLDS.each do |threshold|
        @savings_crossing_year[threshold] ||= year if @total_savings >= threshold
      end
    end

    @first_year = by_year.first.first
  end

  def earned_milestones
    first = Milestone.new(key: :first_adoption, label: 'First adoption', year: @first_year)

    highest_students = highest_earned(STUDENT_THRESHOLDS, @student_crossing_year, :students) do |threshold|
      "#{delimited(threshold)} students"
    end

    highest_savings = highest_earned(SAVINGS_THRESHOLDS, @savings_crossing_year, :savings) do |threshold|
      "#{savings_label(threshold)} saved"
    end

    [first, highest_students, highest_savings].compact.sort_by(&:year)
  end

  def highest_earned(thresholds, crossing_year, unit)
    threshold = thresholds.select { |t| crossing_year[t] }.max
    return nil unless threshold

    Milestone.new(
      key: :"#{unit}_#{threshold}",
      label: yield(threshold),
      year: crossing_year[threshold],
      unit: unit,
      value: threshold
    )
  end

  def next_student_milestone
    threshold = STUDENT_THRESHOLDS.find { |t| @total_students < t }
    return nil unless threshold

    Milestone.new(
      key: :"students_#{threshold}",
      label: "#{delimited(threshold)} students",
      unit: :students,
      value: threshold
    )
  end

  def delimited(number)
    ActiveSupport::NumberHelper.number_to_delimited(number)
  end

  def savings_label(threshold)
    "$#{threshold / 1_000}K"
  end
end
