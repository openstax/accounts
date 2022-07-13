module SheeridAPI
  class Request

    AUTHORIZATION_HEADER = "Bearer #{Rails.application.secrets.sheerid_api_secret}"
    HEADERS = {
      'Authorization': AUTHORIZATION_HEADER,
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }.freeze

    private_constant(:AUTHORIZATION_HEADER, :HEADERS)

    def initialize(http_method, url, request_body = nil)
      @http_method = http_method
      @url = url
      @request_body = request_body
    end

    def response
      @response ||= call_api
    end

    private #################

    def call_api
      http_response = Faraday.send(@http_method, @url, @request_body, HEADERS)
      Response.new(parse_body(http_response.body))
    rescue Net::ReadTimeout => ee
      message = 'SheeridAPI: timeout'
      Sentry.capture_message(message)
      Rails.logger.warn(message)
      return NullResponse.instance
    rescue => ee
      # We don't want explosions here to trickle out and impact callers
      Sentry.capture_exception(ee)
      Rails.logger.warn(ee)
      return NullResponse.instance
    end

    private

    def parse_body(response)
      JSON.parse(response).to_h
    end

  end
end
