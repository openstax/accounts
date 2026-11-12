require 'rails_helper'

RSpec.describe AdoptionBookCatalog do
  let(:cms_books) do
    [
      { subject_name: 'Math', books: [{ title: 'Calculus Volume 1', salesforce_abbreviation: 'Calculus Vol 1' }] },
      { subject_name: 'Science', books: [
        { title: 'AP® Biology', salesforce_abbreviation: 'AP Bio' },
        { title: 'Biology 2e', salesforce_abbreviation: 'Biology' }
      ] },
      { subject_name: 'Science 2', books: [{ title: 'Biology 2e', salesforce_abbreviation: 'Biology' }] }
    ]
  end

  before { allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return(cms_books) }

  it 'lists each book once, sorted by title' do
    expect(described_class.books.map(&:salesforce_abbreviation)).to eq(['AP Bio', 'Biology', 'Calculus Vol 1'])
  end

  describe '.how_using_by_book_for' do
    let(:user) { FactoryBot.create(:user, :terms_agreed, role: 'instructor') }

    def adopt(book, how_using, updated_at)
      Adoption.create!(salesforce_id: SecureRandom.hex(9), user: user, salesforce_book_id: book.salesforce_book_id,
                       how_using: how_using, updated_at: updated_at)
    end

    it 'keys by abbreviation through the title, even when salesforce_name differs, and keeps the newest answer' do
      ap_bio = Book.create!(book_uuid: SecureRandom.uuid, title: 'AP® Biology', salesforce_name: 'AP Biology',
                            salesforce_book_id: 'a0Z1')
      adopt(ap_bio, AdoptionReport::HOW_USING_OPTIONS.second, 2.years.ago)
      adopt(ap_bio, AdoptionReport::HOW_USING_OPTIONS.last, 1.day.ago)

      expect(described_class.how_using_by_book_for(user)).to eq('AP Bio' => AdoptionReport::HOW_USING_OPTIONS.last)
    end
  end
end
