class UpdateBooksFromSalesforce

  def self.call
    new.call
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end

  def call
    log('Starting UpdateBookSalesforceInfo')

    books_updated = 0
    sf_books      = OpenStax::Salesforce::Remote::Book.order(:Id)

    sf_books.each do |sf_book|
      book                 = Book.find_or_initialize_by(salesforce_id: sf_book.id)
      book.salesforce_name = sf_book.name
      book.official_name   = sf_book.official_name

      books_updated        += 1 if book.save!
    end

    log("Finished updating #{books_updated} books")
  end
end
