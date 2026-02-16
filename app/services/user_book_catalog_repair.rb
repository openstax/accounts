class UserBookCatalogRepair
  Result = Struct.new(:scanned, :matched, :repaired, :missing, keyword_init: true)

  def self.call
    new.call
  end

  def call
    catalog = BookCatalog.new.available_books
    lookup = catalog.each_with_object({}) { |entry, memo| memo[entry[:book_uuid].to_s] = entry }
    title_lookup = catalog.each_with_object(Hash.new { |h, k| h[k] = [] }) do |entry, memo|
      memo[entry[:title].to_s.downcase] << entry
    end

    stats = Result.new(scanned: 0, matched: 0, repaired: 0, missing: 0)

    UserBook.includes(:book).find_each do |user_book|
      stats.scanned += 1
      book = user_book.book
      next unless book

      entry = lookup[book.book_uuid.to_s]
      stats.matched += 1 if entry

      unless entry
        candidates = title_lookup[book.title.to_s.downcase]
        entry = candidates.first if candidates.one?
      end

      unless entry
        stats.missing += 1
        next
      end

      book.assign_attributes(
        book_uuid: entry[:book_uuid],
        title: entry[:title],
        cover_url: entry[:cover_url],
        salesforce_name: entry[:salesforce_name],
        assignable_book: ActiveModel::Type::Boolean.new.cast(entry[:assignable_book]),
        webview_rex_link: entry[:webview_rex_link]
      )

      next unless book.changed?

      book.save!
      stats.repaired += 1
    end

    puts "Scanned: #{stats.scanned}, Matched: #{stats.matched}, Repaired: #{stats.repaired}, Missing: #{stats.missing}"
    stats
  end
end
