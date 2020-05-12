require 'net/http'

# Service object for pulling in book data from the CMS
class FetchBookData
  CMS_API_URL = Rails.application.secrets.cms_api_url
  SUBJECTS_URL = "#{CMS_API_URL}snippets/subjects/?format=json"
  TITLES_URL = "#{CMS_API_URL}v2/pages/?type=books.Book&format=json&limit=250&fields=title,book_subjects,book_state"
  TIMEOUT = 1

  def subjects
    @subjects ||= fetch_subjects
  end

  def titles
    @titles ||= fetch_titles
  end

  def fetch_subjects
    results = cms_fetch(SUBJECTS_URL)
    return [] if results.blank?

    results.map  { |subject| subject.fetch('name', nil) }
  end

  def fetch_titles
    results = cms_fetch(TITLES_URL)
    return [] if results.blank?

    items = results.fetch('items', [])
    items.map { |book| book.fetch('title', nil) }
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
      Raven.capture_message("Fetching book data from the CMS timed out")
      return nil
    rescue => ee
      # We don't want explosions here to trickle out and impact callers
      Raven.capture_exception(ee)
      return nil
    end
  end
end
