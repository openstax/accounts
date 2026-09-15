module Account
  class SavedBooksController < Newflow::BaseController
    before_action :newflow_authenticate_user!

    def create
      # Only catalog-sourced attributes may touch the shared Book row —
      # client-supplied fallbacks allowed stored XSS via html_url/title.
      book_attributes = catalog_attributes

      if book_attributes.nil? || book_attributes[:book_uuid].blank? || book_attributes[:title].blank?
        redirect_to account_books_path, alert: 'That book is no longer available.'
        return
      end

      book = Book.find_or_create_from_catalog!(book_attributes)
      saved_book = current_user.user_books.find_or_initialize_by(book: book)

      if saved_book.save
        redirect_to account_books_path, notice: "#{book.title} was saved to your profile."
      else
        redirect_to account_books_path, alert: saved_book.errors.full_messages.to_sentence
      end
    end

    def destroy
      book = current_user.user_books.find_by(id: params[:id])

      if book
        title = book.title
        book.destroy
        redirect_to account_books_path, notice: "#{title} was removed from your list."
      else
        redirect_to account_books_path, alert: 'Book not found.'
      end
    end

    private

    def catalog_attributes
      BookCatalog.new.find(params[:book_uuid])
    end
  end
end
