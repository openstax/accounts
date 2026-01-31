require 'rails_helper'

RSpec.describe SchoolYear do
  include ActiveSupport::Testing::TimeHelpers

  describe '.base_year_for' do
    it 'returns the current year when date is after August' do
      date = Date.new(2025, 9, 5)
      expect(described_class.base_year_for(date)).to eq(2025)
    end

    it 'returns previous year when date is before August' do
      date = Date.new(2025, 5, 1)
      expect(described_class.base_year_for(date)).to eq(2024)
    end
  end

  describe '.label_for' do
    it 'formats the school year correctly' do
      expect(described_class.label_for(2025)).to eq('2025 - 26')
    end
  end

  describe '.current' do
    it 'delegates to base_year_for and label_for' do
      travel_to Time.zone.local(2025, 11, 1)
      expect(described_class.current).to eq('2025 - 26')
      travel_back
    end
  end

  describe '.base_year_from_string' do
    it 'parses the base year from a formatted string' do
      expect(described_class.base_year_from_string('2023 - 24')).to eq(2023)
    end

    it 'returns nil for malformed strings' do
      expect(described_class.base_year_from_string('unknown')).to be_nil
    end
  end
end
