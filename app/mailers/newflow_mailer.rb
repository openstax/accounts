class NewflowMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def newflow_setup_password(user:, email:)
    # @show_pin = ConfirmByPin.sequential_failure_for().attempts_remaining? # TODO
    @user = user
    @casual_name = user.casual_name

    mail to: email, subject: 'Set up a password for your OpenStax account'
  end

  def signup_email_confirmation(email_address:)
    @should_show_pin = ConfirmByPin.sequential_failure_for(email_address).attempts_remaining?
    @email_value = email_address.value
    @confirmation_pin = email_address.confirmation_pin
    @confirmation_code = email_address.confirmation_code
    # TODO: create my own newflow url
    @confirmation_url = signup_verify_by_token_url(code: @confirmation_code)

    mail to: @email_value,
         subject: if @should_show_pin
                    "Use PIN #{@confirmation_pin} to confirm your email address"
                  else
                    'Confirm your email address'
                  end

    email_address.update_column(:confirmation_sent_at, Time.now)
  end
end
