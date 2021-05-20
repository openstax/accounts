require 'rails_helper'
require 'vcr_helper'

describe FetchBookData, type: :lib, vcr: VCR_OPTS do
  describe '#titles' do
    subject(:actual_titles) { described_class.new.titles }

    context 'success' do
      let(:expected_titles) do
        [["Math", [["Prealgebra", "Prealgebra"]]], ["Math", [["Elementary Algebra", "Elementary Algebra"]]], ["Math", [["Intermediate Algebra", "Intermediate Algebra"]]], ["Math", [["College Algebra", "College Algebra"]]], ["Math", [["Algebra and Trigonometry", "Algebra and Trigonometry"]]], ["Math", [["Precalculus", "Precalc"]]], ["Math", [["Calculus Volume 1", "Calculus"]]], ["Math", [["Calculus Volume 2", "Calculus"]]], ["Math", [["Calculus Volume 3", "Calculus"]]], ["Math", [["Introductory Statistics", "Introductory Statistics"]]], ["Math", [["Introductory Business Statistics", "Business Statistics"]]], ["Business", [["Introductory Business Statistics", "Business Statistics"]]], ["Science", [["Anatomy and Physiology", "Anatomy & Physiology"]]], ["Science", [["Astronomy", "Astronomy"]]], ["Science", [["Biology 2e", "Biology"]]], ["Science", [["Concepts of Biology", "Concepts of Bio (non-majors)"]]], ["Science", [["Microbiology", "Microbiology"]]], ["Science", [["Chemistry 2e", "Chemistry"]]], ["Science", [["Chemistry: Atoms First 2e", "Chem: Atoms First"]]], ["Science", [["College Physics", "College Physics (Algebra)"]]], ["Science", [["University Physics Volume 1", "University Physics (Calc)"]]], ["Science", [["University Physics Volume 2", "University Physics (Calc)"]]], ["Science", [["University Physics Volume 3", "University Physics (Calc)"]]], ["Science", [["Biology for AP® Courses", "AP Bio"]]], ["High School", [["Biology for AP® Courses", "AP Bio"]]], ["Science", [["The AP Physics Collection", "AP Physics"]]], ["High School", [["The AP Physics Collection", "AP Physics"]]], ["Social Sciences", [["American Government 2e", "American Government"]]], ["Social Sciences", [["Principles of Economics 2e", "Economics"]]], ["Social Sciences", [["Principles of Macroeconomics 2e", "Macro Econ"]]], ["Social Sciences", [["Principles of Microeconomics 2e", "Micro Econ"]]], ["Social Sciences", [["Psychology", "Psychology"]]], ["Social Sciences", [["Introduction to Sociology 2e", "Introduction to Sociology"]]], ["Social Sciences", [["Principles of Macroeconomics for AP® Courses 2e", "AP Macro Econ"]]], ["High School", [["Principles of Macroeconomics for AP® Courses 2e", "AP Macro Econ"]]], ["Social Sciences", [["Principles of Microeconomics for AP® Courses 2e", "AP Micro Econ"]]], ["High School", [["Principles of Microeconomics for AP® Courses 2e", "AP Micro Econ"]]], ["Humanities", [["U.S. History", "US History"]]], ["Business", [["Introduction to Business", "Introduction to Business"]]], ["Business", [["Business Ethics", "Business Ethics"]]], ["Business", [["Principles of Accounting, Volume 1: Financial Accounting", "Financial Accounting"]]], ["Business", [["Principles of Accounting, Volume 2: Managerial Accounting", "Managerial Accounting"]]], ["Business", [["Principles of Management", "Management"]]], ["Business", [["Entrepreneurship", "Entrepreneurship"]]], ["Business", [["Organizational Behavior", "Organizational Behavior"]]], ["Business", [["Business Law I Essentials", "Business Law I Essentials"]]], ["Essentials", [["Business Law I Essentials", "Business Law I Essentials"]]], ["College Success", [["College Success", "College Success"]]], ["Math", [["Prealgebra 2e", "Prealgebra"]]], ["Math", [["Elementary Algebra 2e", "Elementary Algebra"]]], ["Math", [["Statistics(tc)", "HS Statistics"]]], ["High School", [["Statistics(tc)", "HS Statistics"]]], ["High School", [["Physics", "HS Physics"]]], ["Science", [["Physics", "HS Physics"]]], ["Social Sciences", [["Psychology 2e", "Psychology"]]], ["Math", [["Intermediate Algebra 2e", "Intermediate Algebra"]]]]
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

      it 'calls Sentry with a timed out message' do
        expect(Sentry).to receive(:capture_message).with(/timed out/)
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

      it 'calls Sentry with a timed out message' do
        expect(Sentry).to receive(:capture_exception)
        actual_titles
      end
    end
  end
end
