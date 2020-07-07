module SheeridAPI
  class Request
    AUTHORIZATION_HEADER = "Bearer #{Rails.application.secrets.sheerid_api_secret}"

    HEADERS = {
      'Authorization': AUTHORIZATION_HEADER,
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }.freeze

    def initialize(http_method, url, request_body = nil)
      @http_method = http_method
      @url = url
      @request_body = request_body
    end

    def response
      begin
        response = Faraday.send(@http_method, @url, @request_body, HEADERS)
        return Response.new(parse_body(response.body))
      rescue Net::ReadTimeout => ee
        message = 'SheeridAPI: timeout'
        Raven.capture_message(message)
        Rails.logger.warn(message)
        return NullResponse.instance
      rescue => ee
        # We don't want explosions here to trickle out and impact callers
        Raven.capture_exception(ee)
        Rails.logger.warn(ee)
        return NullResponse.instance
      end
    end

    private

    def parse_body(response)
      JSON.parse(response).to_h
    end
  end
end
