class ConfirmationMailer < ApplicationMailer
  def instructions(email_address:, send_pin: false)
    @email_address = email_address
    @show_pin = send_pin &&
                ConfirmByPin.sequential_failure_for(@email_address).attempts_remaining?

    mail to: "\"#{email_address.user.full_name}\" <#{email_address.value}>",
         subject: @show_pin ?
                    "Use PIN #{@email_address.confirmation_pin} to confirm your email address" :
                    "Confirm your email address"

    email_address.update_column(:confirmation_sent_at, Time.now)
  end

  def signup_email_confirmation(email_address:)
    @should_show_pin = ConfirmByPin.sequential_failure_for(email_address).attempts_remaining?
    @email_value = email_address.value
    @confirmation_pin = email_address.confirmation_pin
    @confirmation_code = email_address.confirmation_code
    @confirmation_url = verify_email_by_code_url(@confirmation_code)

    mail to: @email_value,
         subject: if @should_show_pin
                    "Use PIN #{@confirmation_pin} to confirm your email address"
                  else
                    'Confirm your email address'
                  end

    email_address.update_column(:confirmation_sent_at, Time.now)
  end
end
