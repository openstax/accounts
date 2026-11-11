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
        redirect_to account_books_path, notice: saved_notice(book)
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

    # Flashes render html_safe, so every interpolated value is escaped.
    def saved_notice(book)
      message = ERB::Util.html_escape("#{book.title} was saved to your profile.")
      abbreviation = report_abbreviation_for(book)
      return message if abbreviation.blank?

      nudge = ActionController::Base.helpers.content_tag(
        :span,
        ActionController::Base.helpers.safe_join([
          t('books_report_nudge.saved'), ' ',
          ActionController::Base.helpers.content_tag(
            :button, t('books_report_nudge.saved_action'),
            type: 'button', class: 'account-books__save-nudge-action',
            data: { report_adoption_trigger: 'true', report_adoption_book: abbreviation }
          )
        ]),
        'aria-live': 'polite'
      )
      "#{message} #{nudge}"
    end

    def report_abbreviation_for(book)
      return if current_user.student? || current_user.self_learner?

      AdoptionBookCatalog.books.find { |entry| entry.title == book.title }&.salesforce_abbreviation
    end

    def catalog_attributes
      BookCatalog.new.find(params[:book_uuid])
    end
  end
end
