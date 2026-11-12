require 'rails_helper'

RSpec.describe ImpactMilestones do
  def adoption(year:, students: 0, savings: 0)
    Adoption.new(base_year: year, students: students, savings: savings)
  end

  describe '.for' do
    it 'returns nil when there are no adoptions' do
      expect(described_class.for([])).to be_nil
    end

    it 'always pins "first adoption" to the year of the earliest adoption' do
      result = described_class.for([adoption(year: 2024, students: 10)])

      first = result[:earned].find { |m| m.key == :first_adoption }
      expect(first.year).to eq(2024)
    end

    it 'derives the next student milestone from cumulative students, not any single adoption' do
      adoptions = [
        adoption(year: 2024, students: 60),
        adoption(year: 2025, students: 40) # cumulative 100 -> crosses the 100 threshold
      ]

      result = described_class.for(adoptions)

      expect(result[:students]).to eq(100)
      expect(result[:next].value).to eq(500)
      expect(result[:next].label).to eq('500 students')
    end

    it 'reproduces the design example: first adoption, 100 students, $25K saved, next = 500 students' do
      adoptions = [
        adoption(year: 2024, students: 10, savings: 500),
        adoption(year: 2025, students: 90, savings: 1_500),   # cumulative students crosses 100 (2025)
        adoption(year: 2026, students: 60, savings: 26_560)   # cumulative savings crosses 10K and 25K (2026)
      ]

      result = described_class.for(adoptions)

      expect(result[:students]).to eq(160)
      expect(result[:savings]).to eq(28_560)
      expect(result[:earned].map(&:key)).to eq([:first_adoption, :students_100, :savings_25000])
      expect(result[:earned].map(&:year)).to eq([2024, 2025, 2026])
      expect(result[:next].label).to eq('500 students')
    end

    it 'only shows the highest threshold reached per dimension, not every threshold crossed' do
      # Crosses both 100 and 500 students, and both $10K and $25K savings,
      # all within a single adoption -- only the highest of each should show.
      result = described_class.for([adoption(year: 2024, students: 600, savings: 26_000)])

      expect(result[:earned].size).to eq(3)
      expect(result[:earned].map(&:key)).to include(:first_adoption, :students_500, :savings_25000)
      expect(result[:earned].map(&:key)).not_to include(:students_100, :savings_10000)
    end

    it 'returns nil for :next once every student threshold is cleared' do
      result = described_class.for([adoption(year: 2024, students: 5_000)])

      expect(result[:next]).to be_nil
    end

    it 'ignores adoptions with no derivable school year' do
      adoptions = [adoption(year: 2024, students: 50), Adoption.new(students: 999)]

      result = described_class.for(adoptions)

      expect(result[:students]).to eq(50)
    end
  end
end
