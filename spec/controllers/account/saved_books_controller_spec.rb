require 'rails_helper'

RSpec.describe Account::SavedBooksController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
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
  end
end
