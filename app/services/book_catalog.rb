require 'net/http'

class BookCatalog
  BOOKS_URL = URI('https://openstax.org/apps/cms/api/v2/pages/?type=books.Book&fields=title,salesforce_name,book_uuid,publish_date,assignable_book,cover_url,book_state,webview_rex_link&limit=200')
  ALLOWED_STATES = %w[live deprecated].freeze
  REQUIRED_FIELDS = %w[book_uuid].freeze

  def available_books
    @available_books ||= fetch_books
  end

  def find(book_uuid)
    uuid = book_uuid.to_s
    available_books.find { |book| book[:book_uuid].to_s == uuid }
  end

  private

  def fetch_books
    cache_path = Rails.root.join('config/data/book_catalog_cache.json')
    return [] unless File.exist?(cache_path)

    parse_books(File.read(cache_path))
  end

  def parse_books(json_string)
    json = JSON.parse(json_string)
    items = json['items']
    return [] unless items.is_a?(Array)

    items.map do |item|
      next unless ALLOWED_STATES.include?(item['book_state'])
      next unless REQUIRED_FIELDS.all? { |field| item[field].present? }

      {
        title: item['title'],
        book_uuid: item['book_uuid'],
        cover_url: item['cover_url'],
        webview_rex_link: item['webview_rex_link'],
        html_url: item.dig('meta', 'html_url'),
        salesforce_name: item['salesforce_name'],
        assignable_book: item['assignable_book']
      }
    end.compact
  end


  
end
