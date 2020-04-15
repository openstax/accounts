module Newflow
  class CreateEmailForUser
    lev_routine

    protected ###############

    def exec(email:, user:)
      @email = EmailAddress.create(value: email&.downcase, user_id: user.id)

      @email.customize_value_error_message(
        error: :missing_mx_records,
        message: I18n.t(:"login_signup_form.invalid_email_provider", domain: @email.send(:domain))
      )
      transfer_errors_from(@email, { scope: :email }, :fail_if_errors)

      NewflowMailer.signup_email_confirmation(email_address: @email).deliver_later
    end
  end
end
