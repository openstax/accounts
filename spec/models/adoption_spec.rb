require 'rails_helper'

RSpec.describe Adoption, type: :model do
  describe '#school_year_start' do
    it 'prefers base year when present' do
      adoption = described_class.new(base_year: 2026, school_year: '2024-2025')
      expect(adoption.school_year_start).to eq(2026)
    end

    it 'parses the first year from school_year when base year missing' do
      adoption = described_class.new(school_year: '2025-2026')
      expect(adoption.school_year_start).to eq(2025)
    end

    it 'returns nil when parsing fails' do
      adoption = described_class.new(school_year: 'Unknown')
      expect(adoption.school_year_start).to be_nil
    end
  end

  describe '#savings' do
    it 'persists manual edits to the savings column' do
      adoption = described_class.create!(salesforce_id: SecureRandom.hex(4))
      adoption.update!(savings: 1234.56)

      expect(adoption.reload.savings).to eq(BigDecimal('1234.56'))
    end
  end
end
