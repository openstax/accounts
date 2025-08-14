require_relative 'constants'

module SheeridAPI
  class Request
    include Constants

    def initialize(http_method, url, request_body = nil)
      @http_method = http_method
      @url = url
      @request_body = request_body
    end

    def response
      @response ||= call_api
    end

    private

    def call_api
      http_response = send_request
      Response.new(parse_body(http_response.body))
    rescue Net::ReadTimeout
      handle_timeout
    rescue => ee
      handle_exception(ee)
    end

    def send_request
      case @http_method
      when :get
        Faraday.get(@url, @request_body, HEADERS)
      when :post
        Faraday.post(@url, @request_body, HEADERS)
      else
        raise ArgumentError, "Unsupported HTTP method: #{@http_method}"
      end
    end

    def parse_body(response)
      JSON.parse(response).to_h
    end

    def handle_timeout
      message = 'SheeridAPI: timeout'
      Sentry.capture_message(message)
      Rails.logger.warn(message)
      NullResponse.instance
    end

    def handle_exception(exception)
      Sentry.capture_exception(exception)
      Rails.logger.warn(exception)
      NullResponse.instance
    end
  end
end
