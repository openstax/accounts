module Newflow
  class SendSignupConfirmationEmail
    # Ahead of every other job. Priority rather than a new queue, so workers
    # started with an explicit QUEUES list still run it.
    PRIORITY = -20

    lev_routine

    protected ###############

    def exec(email_address:, show_pin: true)
      delivery = EmailDelivery.track_signup_confirmation!(email_address)

      NewflowMailer.signup_email_confirmation(
        email_address: email_address, show_pin: show_pin, email_delivery_id: delivery.id
      ).deliver_later(priority: PRIORITY)

      outputs.email_delivery = delivery
    end
  end
end
