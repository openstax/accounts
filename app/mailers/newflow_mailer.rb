class NewflowMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def newflow_setup_password(user:, email:)
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

  def reset_password_email(user:, email_address:)
    @user = user

    raise "No valid login token" if user.login_token.nil? || user.login_token_expired?

    mail to: "\"#{user.full_name}\" <#{email_address}>",
         subject: "Reset your OpenStax password"
  end
end
