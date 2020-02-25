module Newflow
  # If a user with the given email address is found, we send (to each of their verified
  # email addresses) an email to reset their password.
  # Otherwise, for security reasons, it returns early with no errors.
  class ResetPassword
    lev_handler

    LOGIN_TOKEN_EXPIRATION = 2.days

    paramify :forgot_password_form do
      attribute :email
    end

    protected #################

    def authorized?
      forgot_password_form_params.email.present? || verified_user
    end

    def handle
      outputs.email = forgot_password_form_params.email
      user = verified_user || LookupUsers.by_verified_email(outputs.email).first

      fatal_error(code: :cannot_find_user,
        offending_inputs: :email,
        message: I18n.t(:"login_signup_form.cannot_find_user")
      ) unless user.present?

      outputs.user = user

      user.refresh_login_token(expiration_period: LOGIN_TOKEN_EXPIRATION)
      user.save
      transfer_errors_from(user, {type: :verbatim}, true)

      email_addresses = user.email_addresses.verified.map(&:value)
      outputs.email ||= email_addresses.first

      email_addresses.each do |email_address|
        NewflowMailer.reset_password_email(user: user, email_address: email_address).deliver_later
      end
    end

    private #################

    def verified_user
      @verified_user ||= caller if caller.present? && !caller.is_anonymous?
    end
  end
end
