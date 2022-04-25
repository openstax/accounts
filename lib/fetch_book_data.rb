require 'net/http'

# Service object for pulling in book data from the CMS
class FetchBookData
  CMS_API_URL = Rails.application.secrets.cms_api_url
  TITLES_URL = "#{CMS_API_URL}v2/pages/?type=books.Book&format=json&limit=250&"\
               "fields=_,title,book_subjects,book_state,salesforce_abbreviation"
  TIMEOUT = 5
  CACHE_DURATION = 1.day

  def titles
    @titles ||= Rails.cache.fetch('BookData.titles', expires_in: CACHE_DURATION) do
      fetch_titles
    end
  end

  def fetch_titles
    results = cms_fetch(TITLES_URL)
    return [] if results.blank?

    items = results.fetch('items', [])
    # All books except for "retired" ones
    books = items.select{ |i| i['book_state'] != 'retired' }

    books_with_subject = []

    books.each { |book|
      book_name = book.fetch('title', nil)
      book_salesforce_name = book.fetch('salesforce_abbreviation', nil)
      next if book_name.nil? || book_salesforce_name.nil?

      subjects = book.fetch('book_subjects', [])

      subjects.each { |subject|
        subject_name = subject.fetch('subject_name', 'missing subject_name')

        books_with_subject << [subject_name, [[book_name, book_salesforce_name]]]
      }
    }

    books_with_subject
  end

  private ###################

  def cms_fetch(uri)
    uri = URI(uri)

    begin
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: TIMEOUT) do |http|
        response = Net::HTTP.get_response(uri)
        body = JSON.parse(response.body)
        return body
      end
    rescue Net::ReadTimeout => ee
      Sentry.capture_message("Fetching book data from the CMS timed out")
      return nil
    rescue => ee
      # We don't want explosions here to trickle out and impact callers
      Sentry.capture_exception(ee)
      return nil
    end
  end
end
