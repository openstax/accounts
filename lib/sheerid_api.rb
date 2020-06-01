# Service object for interacting with SheerID's API
# docs found at: http://developer.sheerid.com/rest-api
class SheeridAPI
  DEFAULT_WEBHOOK_URL = 'https://dev.openstax.org/accounts/i/sheerid/webhook'
  AUTHORIZATION_HEADER = "Bearer #{Rails.application.secrets.sheerid_api_secret}"
  HEADERS = {
    'Authorization': AUTHORIZATION_HEADER,
    'Accept': 'application/json',
    'Content-Type': 'application/json'
  }.freeze

  PROGRAM_ID = ENV['SHEERID_PROGRAM_ID']
  BASE_URL = 'https://services.sheerid.com/rest/v2'

  WEBHOOKS_URL = "#{BASE_URL}/program/#{PROGRAM_ID}/webhook"
  INFO_URL = "#{BASE_URL}/info"
  PROGRAM_THEME_URL = "#{BASE_URL}/#{PROGRAM_ID}/theme"

  class << self
    def get_verification_details(verification_id)
      verification_id_details_url = "#{BASE_URL}/verification/#{verification_id}/details"
      make_request(:get, verification_id_details_url)
    end

    private ###################

    def make_request(http_method, url, body = nil)
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

    def create_verification_webook(url)
      body = { 'callbackUri': url }.to_json
      make_request(:post, WEBHOOKS_URL, body)
    end

    def delete_verification_webook
      make_request(:delete, WEBHOOKS_URL)
    end

    def update_webhook_url(url = DEFAULT_WEBHOOK_URL)
      delete_verification_webook && create_verification_webook(url)
    end

    def info
      make_request(:get, INFO_URL)
    end

    def is_verified?(verification_id)
      response_json = get_verification_details(verification_id)
      current_step = response_json.fetch('lastResponse', {}).fetch('currentStep', nil)
      current_step == 'success'
    end
  end
end
