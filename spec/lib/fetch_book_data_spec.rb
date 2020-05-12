require 'rails_helper'
require 'vcr_helper'

describe FetchBookData, type: :lib, vcr: VCR_OPTS do
  describe '#subjects' do
    subject(:actual_subjects) { described_class.new.subjects }

    context 'success' do
      let(:expected_subjects) do
        ["Math", "Science", "Humanities", "Social Sciences", "Business", "Essentials", "College Success", "High School"]
      end

      example do
        expect(actual_subjects).to match(expected_subjects)
      end
    end

    context 'when there is a timeout' do
      before do
        # cannot really test read timeout b/c of how webmock inserts itself
        # https://github.com/bblimke/webmock/issues/286#issuecomment-19457387
        allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
      end

      it 'returns empty array' do
        expect(actual_subjects).to match([])
      end

      it 'calls Raven with a timed out message' do
        expect(Raven).to receive(:capture_message).with(/timed out/)
        actual_subjects
      end
    end

    context 'when there is any other exception' do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(StandardError)
      end

      it 'returns empty array' do
        expect(actual_subjects).to match([])
      end

      it 'calls Raven with a timed out message' do
        expect(Raven).to receive(:capture_exception)
        actual_subjects
      end
    end
  end

  describe '#titles' do
    subject(:actual_titles) { described_class.new.titles }

    context 'success' do
      let(:expected_titles) do
        ["Prealgebra", "Elementary Algebra", "Intermediate Algebra", "College Algebra", "Algebra and Trigonometry", "Precalculus", "Calculus Volume 1", "Calculus Volume 2", "Calculus Volume 3", "Introductory Statistics", "Introductory Business Statistics", "Anatomy and Physiology", "Astronomy", "Biology 2e", "Concepts of Biology", "Microbiology", "Chemistry 2e", "Chemistry: Atoms First 2e", "College Physics", "University Physics Volume 1", "University Physics Volume 2", "University Physics Volume 3", "Biology for AP® Courses", "The AP Physics Collection", "Fizyka dla szkół wyższych. Tom 1", "Fizyka dla szkół wyższych. Tom 2", "Fizyka dla szkół wyższych. Tom 3", "American Government 2e", "Principles of Economics 2e", "Principles of Macroeconomics 2e", "Principles of Microeconomics 2e", "Psychology", "Introduction to Sociology 2e", "Principles of Macroeconomics for AP® Courses 2e", "Principles of Microeconomics for AP® Courses 2e", "U.S. History", "Introduction to Business", "Business Ethics", "Principles of Accounting, Volume 1: Financial Accounting", "Principles of Accounting, Volume 2: Managerial Accounting", "Principles of Management", "Entrepreneurship", "Organizational Behavior", "Business Law I Essentials", "College Success", "Prealgebra 2e", "Elementary Algebra 2e", "Statistics", "Physics", "Psychology 2e", "Intermediate Algebra 2e", "Life, Liberty, and the Pursuit of Happiness"]
      end

      example do
        expect(actual_titles).to match(expected_titles)
      end
    end

    context 'when there is a timeout' do
      before do
        # cannot really test read timeout b/c of how webmock inserts itself
        # https://github.com/bblimke/webmock/issues/286#issuecomment-19457387
        allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
      end

      it 'returns empty array' do
        expect(actual_titles).to match([])
      end

      it 'calls Raven with a timed out message' do
        expect(Raven).to receive(:capture_message).with(/timed out/)
        actual_titles
      end
    end

    context 'when there is any other exception' do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(StandardError)
      end

      it 'returns empty array' do
        expect(actual_titles).to match([])
      end

      it 'calls Raven with a timed out message' do
        expect(Raven).to receive(:capture_exception)
        actual_titles
      end
    end
  end
end
