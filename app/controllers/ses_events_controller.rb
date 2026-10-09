# Accepts only SNS-signed messages from the configured topic
class SesEventsController < ActionController::API
  SNS_HOST = /\Asns\.[a-z0-9-]+\.amazonaws\.com\z/

  def create
    body = request.raw_post
    message = parse_json(body)
    return head(:bad_request) unless message.is_a?(Hash)
    return head(:forbidden) unless expected_topic?(message['TopicArn']) && authentic?(body)

    case message['Type']
    when 'SubscriptionConfirmation'
      confirm_subscription(message['SubscribeURL'])
    when 'Notification'
      event = parse_json(message['Message'])
      ProcessSesEvent.call(event: event) if event.is_a?(Hash)
    end

    head :ok
  end

  def self.verifier
    require 'aws-sdk-sns'
    @verifier ||= Aws::SNS::MessageVerifier.new
  end

  private

  def parse_json(text)
    JSON.parse(text.to_s)
  rescue JSON::ParserError
    nil
  end

  def expected_topic?(topic_arn)
    configured = Rails.application.secrets.dig(:aws, :ses, :events_topic_arn)
    configured.present? && ActiveSupport::SecurityUtils.secure_compare(configured, topic_arn.to_s)
  end

  def authentic?(body)
    self.class.verifier.authentic?(body)
  end

  def confirm_subscription(subscribe_url)
    uri = URI.parse(subscribe_url.to_s)
    unless uri.is_a?(URI::HTTPS) && SNS_HOST.match?(uri.host.to_s)
      Sentry.capture_message('[SES events] Refused a SubscribeURL outside SNS', level: :warning)
      return
    end

    response = Net::HTTP.get_response(uri)
    Rails.logger.info("[SES events] Confirmed SNS subscription: HTTP #{response.code}")
  end
end
