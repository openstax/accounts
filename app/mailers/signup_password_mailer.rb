class SignupPasswordMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  # Technical debt - I don't know how - Roy
  # rubocop:disable Rails/I18nLocaleTexts
  def create_password_email(user:, email:)
    @user = user
    mail to: email, subject: 'Set up a password for your OpenStax account'
  end

  def reset_password_email(user:, email_address:)
    @user = user

    raise "No valid login token" if user.login_token.nil? || user.login_token_expired?

    mail to: "\"#{user.full_name}\" <#{email_address}>",
         subject: "Reset your OpenStax password"
  end
  # rubocop:enable Rails/I18nLocaleTexts

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
    # rubocop:disable Rails/SkipsModelValidations
    email_address.update_columns(confirmation_sent_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
