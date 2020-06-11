# Service object for interacting with SheerID's API
# docs found at: http://developer.sheerid.com/rest-api
class SheeridAPI
  AUTHORIZATION_HEADER = "Bearer #{Rails.application.secrets.sheerid_api_secret}"
  HEADERS = {
    'Authorization': AUTHORIZATION_HEADER,
    'Accept': 'application/json',
    'Content-Type': 'application/json'
  }.freeze

  BASE_URL = 'https://services.sheerid.com/rest/v2'

  def self.get_verification_details(verification_id)
    verification_id_details_url = "#{BASE_URL}/verification/#{verification_id}/details"
    make_request(:get, verification_id_details_url)
  end

  private ###################

  def self.make_request(http_method, url, body = nil)
    begin
      response = Faraday.send(http_method, url, body, HEADERS)
      body = JSON.parse(response.body)
      return body
    rescue Net::ReadTimeout => ee
      Raven.capture_message("SheeridAPI: timeout")
      return nil
    rescue => ee
      # We don't want explosions here to trickle out and impact callers
      Raven.capture_exception(ee)
      return nil
    end
  end
end
