require 'rails_helper'

RSpec.describe Account::SavedBooksController, type: :controller do
  let(:user) { FactoryBot.create(:user, :terms_agreed) }
  let(:catalog_entry) do
    {
      book_uuid: 'abc-123',
      title: 'Test Book',
      cover_url: 'https://example.org/cover.svg',
      salesforce_name: 'Test Book',
      assignable_book: true,
      webview_rex_link: 'https://openstax.org/books/test/pages/1',
      html_url: 'https://openstax.org/details/books/test'
    }
  end

  before do
    allow(controller).to receive(:newflow_authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '#create' do
    it 'stores the canonical catalog UUID on the saved book' do
      catalog = instance_double(BookCatalog)
      allow(BookCatalog).to receive(:new).and_return(catalog)
      allow(catalog).to receive(:find).with('abc-123').and_return(catalog_entry)

      expect {
        post :create, params: { book_uuid: 'abc-123' }
      }.to change { UserBook.count }.by(1)

      saved_book = UserBook.last
      expect(saved_book.book.book_uuid).to eq('abc-123')
      expect(saved_book.book.title).to eq('Test Book')
    end

    context 'for an instructor whose book is in the report catalog' do
      let(:user) { FactoryBot.create(:user, :terms_agreed, role: :instructor) }

      before do
        catalog = instance_double(BookCatalog)
        allow(BookCatalog).to receive(:new).and_return(catalog)
        allow(catalog).to receive(:find).with('abc-123').and_return(catalog_entry.merge(title: 'Test <b>Book</b>'))
        allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return([
          { subject_name: 'Science', books: [{ title: 'Test <b>Book</b>', salesforce_abbreviation: 'Test Abbr' }] }
        ])
      end

      it 'adds a polite nudge that opens the report modal with the book preselected, and escapes the title' do
        post :create, params: { book_uuid: 'abc-123' }

        expect(flash[:notice]).to include('Teaching with it this term?')
        expect(flash[:notice]).to include('aria-live="polite"')
        expect(flash[:notice]).to include('data-report-adoption-trigger="true"')
        expect(flash[:notice]).to include('data-report-adoption-book="Test Abbr"')
        expect(flash[:notice]).to include('Test &lt;b&gt;Book&lt;/b&gt; was saved to your profile.')
      end
    end

    it 'keeps the plain confirmation for a student' do
      catalog = instance_double(BookCatalog)
      allow(BookCatalog).to receive(:new).and_return(catalog)
      allow(catalog).to receive(:find).with('abc-123').and_return(catalog_entry)

      post :create, params: { book_uuid: 'abc-123' }

      expect(flash[:notice]).to eq('Test Book was saved to your profile.')
    end

    it 'rejects books not found in the catalog instead of trusting client params' do
      catalog = instance_double(BookCatalog)
      allow(BookCatalog).to receive(:new).and_return(catalog)
      allow(catalog).to receive(:find).with('evil-uuid').and_return(nil)

      expect {
        post :create, params: {
          book_uuid: 'evil-uuid',
          title: 'x',
          html_url: 'javascript:alert(1)',
          assignable_book: true
        }
      }.not_to change { [UserBook.count, Book.count] }

      expect(response).to redirect_to(account_books_path)
      expect(flash[:alert]).to eq('That book is no longer available.')
    end
  end
end
