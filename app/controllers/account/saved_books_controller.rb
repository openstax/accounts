module Account
  class SavedBooksController < Newflow::BaseController
    before_action :newflow_authenticate_user!

    def create
      book_attributes = catalog_attributes || fallback_book_params

      if book_attributes[:book_uuid].blank? || book_attributes[:title].blank?
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

    def fallback_book_params
      params.permit(:book_uuid, :title, :cover_url, :salesforce_name, :assignable_book, :webview_rex_link, :html_url)
            .to_h.symbolize_keys
    end
  end
end
