require 'rails_helper'

describe TermOptions do
  describe '.upcoming' do
    it 'returns the soonest terms plus a year-long option, computed from the given date' do
      # Mid-July 2026 — mirrors the design reference: the next term to start
      # is Fall 2026, not the (already-underway) Summer 2026 term.
      terms = TermOptions.upcoming(Date.new(2026, 7, 19))

      expect(terms).to eq(['Fall 2026', 'Spring 2027', 'Summer 2027', 'Year-long 2026–27'])
    end

    it 'rolls into a Spring-starting sequence just after New Year' do
      terms = TermOptions.upcoming(Date.new(2027, 1, 5))

      expect(terms).to eq(['Spring 2027', 'Summer 2027', 'Fall 2027', 'Year-long 2026–27'])
    end

    it 'respects a custom count' do
      terms = TermOptions.upcoming(Date.new(2026, 7, 19), count: 1)

      expect(terms).to eq(['Fall 2026', 'Year-long 2026–27'])
    end
  end
end
