require 'rails_helper'
require 'vcr_helper'

describe FetchBookData, type: :lib, vcr: VCR_OPTS do
  describe '#titles' do
    subject(:actual_titles) { described_class.new.titles }

    context 'success' do
      let(:expected_titles) do
        [["Math", [["Prealgebra", "Prealgebra"]]], ["Math", [["Elementary Algebra", "Elementary Algebra"]]], ["Math", [["Intermediate Algebra", "Intermediate Algebra"]]], ["Math", [["College Algebra", "College Algebra"]]], ["Math", [["Algebra and Trigonometry", "Algebra and Trigonometry"]]], ["Math", [["Precalculus", "Precalc"]]], ["Math", [["Calculus Volume 1", "Calculus"]]], ["Math", [["Calculus Volume 2", "Calculus"]]], ["Math", [["Calculus Volume 3", "Calculus"]]], ["Math", [["Introductory Statistics", "Introductory Statistics"]]], ["Math", [["Introductory Business Statistics", "Business Statistics"]]], ["Business", [["Introductory Business Statistics", "Business Statistics"]]], ["Science", [["Anatomy and Physiology", "Anatomy & Physiology"]]], ["Science", [["Astronomy", "Astronomy"]]], ["Science", [["Biology 2e", "Biology"]]], ["Science", [["Concepts of Biology", "Concepts of Bio (non-majors)"]]], ["Science", [["Microbiology", "Microbiology"]]], ["Science", [["Chemistry 2e", "Chemistry"]]], ["Science", [["Chemistry: Atoms First 2e", "Chem: Atoms First"]]], ["Science", [["College Physics", "College Physics (Algebra)"]]], ["Science", [["University Physics Volume 1", "University Physics (Calc)"]]], ["Science", [["University Physics Volume 2", "University Physics (Calc)"]]], ["Science", [["University Physics Volume 3", "University Physics (Calc)"]]], ["Science", [["Biology for AP® Courses", "AP Bio"]]], ["High School", [["Biology for AP® Courses", "AP Bio"]]], ["Science", [["The AP Physics Collection", "AP Physics"]]], ["High School", [["The AP Physics Collection", "AP Physics"]]], ["Social Sciences", [["American Government 2e", "American Government"]]], ["Social Sciences", [["Principles of Economics 2e", "Economics"]]], ["Social Sciences", [["Principles of Macroeconomics 2e", "Macro Econ"]]], ["Social Sciences", [["Principles of Microeconomics 2e", "Micro Econ"]]], ["Social Sciences", [["Psychology", "Psychology"]]], ["Social Sciences", [["Introduction to Sociology 2e", "Introduction to Sociology"]]], ["Social Sciences", [["Principles of Macroeconomics for AP® Courses 2e", "AP Macro Econ"]]], ["High School", [["Principles of Macroeconomics for AP® Courses 2e", "AP Macro Econ"]]], ["Social Sciences", [["Principles of Microeconomics for AP® Courses 2e", "AP Micro Econ"]]], ["High School", [["Principles of Microeconomics for AP® Courses 2e", "AP Micro Econ"]]], ["Humanities", [["U.S. History", "US History"]]], ["Business", [["Introduction to Business", "Introduction to Business"]]], ["Business", [["Business Ethics", "Business Ethics"]]], ["Business", [["Principles of Accounting, Volume 1: Financial Accounting", "Financial Accounting"]]], ["Business", [["Principles of Accounting, Volume 2: Managerial Accounting", "Managerial Accounting"]]], ["Business", [["Principles of Management", "Management"]]], ["Business", [["Entrepreneurship", "Entrepreneurship"]]], ["Business", [["Organizational Behavior", "Organizational Behavior"]]], ["Business", [["Business Law I Essentials", "Business Law I Essentials"]]], ["Essentials", [["Business Law I Essentials", "Business Law I Essentials"]]], ["College Success", [["College Success", "College Success"]]], ["Math", [["Prealgebra 2e", "Prealgebra"]]], ["Math", [["Elementary Algebra 2e", "Elementary Algebra"]]], ["Math", [["Statistics(tc)", "HS Statistics"]]], ["High School", [["Statistics(tc)", "HS Statistics"]]], ["High School", [["Physics", "HS Physics"]]], ["Science", [["Physics", "HS Physics"]]], ["Social Sciences", [["Psychology 2e", "Psychology"]]], ["Math", [["Intermediate Algebra 2e", "Intermediate Algebra"]]]]
      end

      # TODO: a hard-coded list of our books is not a good test of this functionality - maybe what is below is enough?
      # example do
      #   expect(actual_titles).to include("Math")
      # end
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

describe FetchBookData, type: :lib do
  def book(attrs = {})
    { 'title' => 'A Book', 'salesforce_abbreviation' => 'A Book' }.merge(attrs)
  end

  def stub_cms(url, body)
    fetcher = described_class.new
    allow(fetcher).to receive(:cms_fetch).with(url).and_return(body)
    fetcher
  end

  describe '#fetch_titles' do
    def abbreviations_for(books)
      items = books.map { |b| b.merge('book_subjects' => [{ 'subject_name' => 'Business' }]) }
      fetcher = stub_cms(described_class::TITLES_URL, 'items' => items)

      fetcher.fetch_titles.map { |_subject, titles| titles.first.last }
    end

    it 'lists only live, new edition and coming soon books' do
      states = %w[live new_edition_available coming_soon deprecated retired unlisted]
      books = states.map { |state| book('salesforce_abbreviation' => state, 'book_state' => state) }

      expect(abbreviations_for(books)).to eq(%w[live new_edition_available coming_soon])
    end

    it 'drops a book with no state or an unrecognized one' do
      books = [book('salesforce_abbreviation' => 'no state'),
               book('salesforce_abbreviation' => 'odd', 'book_state' => 'something_new'),
               book('salesforce_abbreviation' => 'live', 'book_state' => 'live')]

      expect(abbreviations_for(books)).to eq(['live'])
    end
  end

  describe '#fetch_books_by_subject' do
    def books_for(books)
      items = books.map { |b| b.merge('subjects' => ['Business']) }
      fetcher = stub_cms(described_class::SUBJECTS_URL, 'books' => items)

      fetcher.fetch_books_by_subject.flat_map { |subject| subject[:books] }
    end

    it 'lists only live, new edition and coming soon books' do
      states = %w[live new_edition_available coming_soon deprecated retired unlisted]
      books = states.map { |state| book('salesforce_abbreviation' => state, 'book_state' => state) }

      expect(books_for(books).map { |b| b[:salesforce_abbreviation] })
        .to match_array(%w[live new_edition_available coming_soon])
    end

    it 'drops a book with no state or an unrecognized one' do
      books = [book('salesforce_abbreviation' => 'no state'),
               book('salesforce_abbreviation' => 'odd', 'book_state' => 'something_new'),
               book('salesforce_abbreviation' => 'live', 'book_state' => 'live')]

      expect(books_for(books).map { |b| b[:salesforce_abbreviation] }).to eq(['live'])
    end

    it 'shows the live edition, not an older one that sorts first and shares its abbreviation' do
      old_edition = book('title' => 'Principles of Finance', 'salesforce_abbreviation' => 'Finance',
                         'book_state' => 'deprecated', 'cover_url' => 'old.png')
      new_edition = book('title' => 'Principles of Finance 2e', 'salesforce_abbreviation' => 'Finance',
                         'book_state' => 'live', 'cover_url' => 'new.png')

      expect(books_for([old_edition, new_edition]))
        .to eq([{ title: 'Principles of Finance 2e', salesforce_abbreviation: 'Finance',
                  cover_url: 'new.png' }])
    end
  end

  describe '#abbreviations_by_slug' do
    let(:body) do
      {
        'items' => [
          { 'meta' => { 'slug' => 'psychology-2e' }, 'salesforce_abbreviation' => 'Psychology' },
          { 'meta' => { 'slug' => 'psychology' }, 'salesforce_abbreviation' => 'Psychology' },
          { 'meta' => { 'slug' => 'polish-book' }, 'salesforce_abbreviation' => nil },
          { 'meta' => { 'slug' => 'unlisted-book' }, 'salesforce_abbreviation' => '' }
        ]
      }
    end

    it 'maps every slug with an abbreviation, whatever the book state' do
      allow_any_instance_of(described_class).to receive(:cms_fetch).with(described_class::SLUGS_URL).and_return(body)

      expect(described_class.new.abbreviations_by_slug).to eq(
        'psychology-2e' => 'Psychology', 'psychology' => 'Psychology'
      )
    end

    it 'returns an empty hash and does not cache when the fetch fails' do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      calls = [nil, body]
      allow_any_instance_of(described_class).to receive(:cms_fetch) { calls.shift }

      expect(described_class.new.abbreviations_by_slug).to eq({})
      expect(described_class.new.abbreviations_by_slug).to include('psychology-2e' => 'Psychology')
    end
  end
end
