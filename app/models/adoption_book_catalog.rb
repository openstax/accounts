# Books offered in the report-an-adoption modal, from the CMS (cached by FetchBookData).
# Salesforce matches an adoption's book by salesforce_abbreviation, not by title.
class AdoptionBookCatalog
  Book = Struct.new(:title, :salesforce_abbreviation, keyword_init: true)

  def self.books
    new.books
  end

  # {abbreviation => how_using} from the user's most recent adoption of each book,
  # so the modal can prefill what they said last time.
  def self.how_using_by_book_for(user)
    user.adoptions.includes(:book).where.not(how_using: [nil, ''])
        .order(updated_at: :desc, id: :desc)
        .each_with_object({}) do |adoption, map|
      name = adoption.book&.salesforce_name
      next if name.blank? || map.key?(name) || !AdoptionReport::HOW_USING_OPTIONS.include?(adoption.how_using)

      map[name] = adoption.how_using
    end
  end

  def books
    FetchBookData.new.books_by_subject
                 .flat_map { |subject| subject[:books] }
                 .uniq { |book| book[:salesforce_abbreviation] }
                 .sort_by { |book| book[:title] }
                 .map { |book| Book.new(title: book[:title], salesforce_abbreviation: book[:salesforce_abbreviation]) }
  end

  def title_for(abbreviation)
    books.find { |book| book.salesforce_abbreviation == abbreviation }&.title
  end
end
