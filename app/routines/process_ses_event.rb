class ProcessSesEvent
  lev_routine

  protected

  def exec(event:)
    mail = event['mail'] || {}
    tags = mail['tags'] || {}
    return if Array(tags['accounts_env']).first != EmailDelivery.environment_tag

    delivery = EmailDelivery.find_by(id: Array(tags['email_delivery_id']).first)
    return if delivery.nil?

    status, detail, at, attributes = interpret(event)
    return if status.nil?

    delivery.advance!(
      status,
      detail: detail,
      at: at || Time.current,
      ses_message_id: delivery.ses_message_id || mail['messageId'],
      last_event: event.except('mail').merge('mail' => mail.except('headers')),
      **attributes
    )
    outputs.email_delivery = delivery
  end

  private

  def interpret(event)
    case event['eventType'] || event['notificationType']
    when 'Send'
      [:sent, nil, time(event.dig('mail', 'timestamp')), {}]
    when 'Delivery'
      delivery = event['delivery'] || {}
      at = time(delivery['timestamp'])
      [:delivered, delivery['smtpResponse'], at, { delivered_at: at }]
    when 'DeliveryDelay'
      delay = event['deliveryDelay'] || {}
      recipient = Array(delay['delayedRecipients']).first || {}
      detail = [delay['delayType'], recipient['diagnosticCode']].compact.join(': ')
      detail += " (SES keeps retrying until #{delay['expirationTime']})" if delay['expirationTime']
      [:delayed, detail, time(delay['timestamp']), {}]
    when 'Bounce'
      bounce = event['bounce'] || {}
      recipient = Array(bounce['bouncedRecipients']).first || {}
      detail = ["#{bounce['bounceType']}/#{bounce['bounceSubType']}", recipient['diagnosticCode']]
      [:bounced, detail.compact.join(': '), time(bounce['timestamp']), {}]
    when 'Complaint'
      complaint = event['complaint'] || {}
      [:complained, complaint['complaintFeedbackType'], time(complaint['timestamp']), {}]
    when 'Reject'
      [:rejected, event.dig('reject', 'reason'), nil, {}]
    when 'Rendering Failure'
      [:rejected, event.dig('failure', 'errorMessage'), nil, {}]
    end
  end

  def time(value)
    Time.zone.parse(value) if value.present?
  rescue ArgumentError
    nil
  end
end
