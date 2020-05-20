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
        expect(actual_subjects).to match_array(expected_subjects)
      end
    end

    context 'when there is a timeout' do
      before do
        # cannot really test read timeout b/c of how webmock inserts itself
        # https://github.com/bblimke/webmock/issues/286#issuecomment-19457387
        allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
      end

      it 'returns empty array' do
        expect(actual_subjects).to match_array([])
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
        expect(actual_subjects).to match_array([])
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
        [
          ["Business", ["Introductory Business Statistics"]],
          ["Business", ["Introduction to Business"]],
          ["Business", ["Business Ethics"]],
          ["Business", ["Principles of Accounting, Volume 1: Financial Accounting"]],
          ["Business", ["Principles of Accounting, Volume 2: Managerial Accounting"]],
          ["Business", ["Principles of Management"]],
          ["Business", ["Entrepreneurship"]],
          ["Business", ["Organizational Behavior"]],
          ["Business", ["Business Law I Essentials"]],
          ["College Success", ["College Success"]],
          ["Essentials", ["Business Law I Essentials"]],
          ["High School", ["Biology for AP® Courses"]],
          ["High School", ["The AP Physics Collection"]],
          ["High School", ["Principles of Macroeconomics for AP® Courses 2e"]],
          ["High School", ["Principles of Microeconomics for AP® Courses 2e"]],
          ["High School", ["Statistics"]],
          ["High School", ["Physics"]],
          ["High School", ["Life, Liberty, and the Pursuit of Happiness"]],
          ["Humanities", ["U.S. History"]],
          ["Humanities", ["Life, Liberty, and the Pursuit of Happiness"]],
          ["Math", ["Elementary Algebra"]],
          ["Math", ["Intermediate Algebra"]],
          ["Math", ["College Algebra"]],
          ["Math", ["Algebra and Trigonometry"]],
          ["Math", ["Precalculus"]],
          ["Math", ["Calculus Volume 1"]],
          ["Math", ["Calculus Volume 2"]],
          ["Math", ["Calculus Volume 3"]],
          ["Math", ["Introductory Statistics"]],
          ["Math", ["Introductory Business Statistics"]],
          ["Math", ["Intermediate Algebra 2e"]],
          ["Math", ["Prealgebra 2e"]],
          ["Math", ["Elementary Algebra 2e"]],
          ["Math", ["Statistics"]],
          ["Science", ["Astronomy"]],
          ["Science", ["Biology 2e"]],
          ["Science", ["Concepts of Biology"]],
          ["Science", ["Microbiology"]],
          ["Science", ["Chemistry 2e"]],
          ["Science", ["Chemistry: Atoms First 2e"]],
          ["Science", ["College Physics"]],
          ["Science", ["University Physics Volume 1"]],
          ["Science", ["University Physics Volume 2"]],
          ["Science", ["University Physics Volume 3"]],
          ["Science", ["Biology for AP® Courses"]],
          ["Science", ["The AP Physics Collection"]],
          ["Science", ["Physics"]],
          ["Social Sciences", ["Psychology 2e"]],
          ["Science", ["Fizyka dla szkół wyższych. Tom 1"]],
          ["Science", ["Fizyka dla szkół wyższych. Tom 2"]],
          ["Science", ["Fizyka dla szkół wyższych. Tom 3"]],
          ["Social Sciences", ["American Government 2e"]],
          ["Social Sciences", ["Principles of Economics 2e"]],
          ["Social Sciences", ["Principles of Macroeconomics 2e"]],
          ["Social Sciences", ["Principles of Microeconomics 2e"]],
          ["Social Sciences", ["Psychology"]],
          ["Social Sciences", ["Introduction to Sociology 2e"]],
          ["Social Sciences", ["Principles of Macroeconomics for AP® Courses 2e"]],
          ["Social Sciences", ["Principles of Microeconomics for AP® Courses 2e"]],
        ]
      end

      example do
        expect(actual_titles).to match_array(expected_titles)
      end
    end

    context 'when there is a timeout' do
      before do
        # cannot really test read timeout b/c of how webmock inserts itself
        # https://github.com/bblimke/webmock/issues/286#issuecomment-19457387
        allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
      end

      it 'returns empty array' do
        expect(actual_titles).to match_array([])
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
        expect(actual_titles).to match_array([])
      end

      it 'calls Raven with a timed out message' do
        expect(Raven).to receive(:capture_exception)
        actual_titles
      end
    end
  end
end
