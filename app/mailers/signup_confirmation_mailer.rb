class SignupConfirmationMailer < ApplicationMailer

  def instructions(pre_auth_state:)
    @pre_auth_state = pre_auth_state
    @show_pin = ConfirmByPin.sequential_failure_for(@pre_auth_state).attempts_remaining?

    res = mail to: "#{pre_auth_state.contact_info_value}",
         subject: @show_pin ?
                    "Use PIN #{pre_auth_state.confirmation_pin} to confirm your email address" :
                    "Confirm your email address"

    pre_auth_state.update_column(:confirmation_sent_at, Time.now)
  end

# primarily used for testing the deliverability of the PIN confirmation emails
  def pin_confirmation_email(email_address:, confirmation_pin:, confirmation_token:, user_full_name:)
    @email_address = email_address
    @user_full_name = user_full_name
    @confirmation_pin = confirmation_pin
    @confirmation_token = confirmation_token

    mail(to: "\"#{@user_full_name}\" <#{@email_address}>",
      subject: "Use PIN #{@confirmation_pin} to confirm your email address"
    )
  end
end
