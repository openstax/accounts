module AdminEmailDeliveryHelper
  EMAIL_DELIVERY_LABELS = {
    'queued' => ['Waiting to send', 'default',
                 'Queued in Accounts, not yet handed to Amazon SES. More than a few ' \
                 'minutes here means our background workers are backed up.'],
    'send_error' => ['Send failed, retrying', 'warning',
                     'Amazon SES refused or timed out; Accounts retries automatically.'],
    'sent' => ['Sent', 'info',
               'Handed to Amazon SES. No word yet from the recipient\'s mail server.'],
    'delayed' => ['Delayed', 'warning',
                  'The recipient\'s mail server is turning it away for now (common with ' \
                  'school filters). SES keeps retrying, so it may still arrive.'],
    'delivered' => ['Delivered', 'success',
                    'Accepted by the recipient\'s mail server. If they can\'t find it, it\'s ' \
                    'in spam, junk or a school quarantine.'],
    'bounced' => ['Bounced', 'danger',
                  'The recipient\'s mail server rejected it. Check the address for a typo; ' \
                  'it may not exist.'],
    'complained' => ['Marked as spam', 'danger',
                     'The recipient (or their mail filter) reported it as spam.'],
    'rejected' => ['Not sent', 'danger',
                   'Amazon SES refused the message, so it was never sent. Usually a ' \
                   'malformed address.']
  }.freeze

  def email_delivery_badge(delivery)
    text, style, explanation = EMAIL_DELIVERY_LABELS.fetch(delivery.status)
    content_tag(:span, text, class: "label label-#{style}", title: explanation)
  end

  def email_delivery_explanation(delivery)
    EMAIL_DELIVERY_LABELS.fetch(delivery.status).last
  end

  def email_delivery_duration(seconds)
    return if seconds.nil?
    return "#{seconds}s" if seconds < 60
    return "#{(seconds / 60.0).round(1)} min" if seconds < 3600

    "#{(seconds / 3600.0).round(1)} h"
  end
end
