# Permanent SES rejections are recorded by ApplicationMailer's rescue_from, not here
class TrackedMailDeliveryJob < ActionMailer::MailDeliveryJob
  def perform(mailer, mail_method, delivery_method, args:, kwargs: nil, params: nil)
    delivery = email_delivery(args, kwargs)
    return super if delivery.nil?

    delivery.increment!(:send_attempts)

    begin
      message = super
    rescue StandardError => e
      delivery.advance!(:send_error, detail: "#{e.class}: #{e.message}")
      raise
    end

    delivery.advance!(
      :sent, sent_at: Time.current, ses_message_id: message.try(:header)&.[](:ses_message_id)&.to_s
    )
    message
  end

  private

  def email_delivery(args, kwargs)
    options = [*args, kwargs].grep(Hash).find { |hash| hash.key?(:email_delivery_id) }
    EmailDelivery.find_by(id: options[:email_delivery_id]) if options
  end
end
