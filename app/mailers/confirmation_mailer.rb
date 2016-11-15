class ConfirmationMailer < SiteMailer

  def instructions(email_address:, send_pin: false)
    @email_address = email_address
    @show_pin = send_pin &&
                ConfirmByPin.sequential_failure_for(@email_address).attempts_remaining?

    mail to: "\"#{email_address.user.full_name}\" <#{email_address.value}>",
         subject: @show_pin ? "Verify your email address using code #{@email_address.confirmation_pin}" :
                              "Verify your email address"

    email_address.update_column(:confirmation_sent_at, Time.now)
  end
end
