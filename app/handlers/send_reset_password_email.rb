# If a user with the given email address is found, OR if there is a logged in user,
#  we send (to each of their verified email addresses)
# an email to reset their password.
class SendResetPasswordEmail
  lev_handler

  LOGIN_TOKEN_EXPIRATION = 2.days

  paramify :forgot_password_form do
    attribute :email
  end

  protected #################

  def authorized?
    true
  end

  def handle
    outputs.email = forgot_password_form_params.email
    outputs.email.squish! if outputs.email.present?

    fatal_error(code: :email_is_blank,
      offending_inputs: :email,
      message: I18n.t(:"login_signup_form.email_is_blank")
    ) unless outputs.email.present? || logged_in_user

    user = logged_in_user || find_user(outputs.email)

    fatal_error(code: :cannot_find_user,
      offending_inputs: :email,
      message: I18n.t(:"login_signup_form.cannot_find_user")
    ) unless user.present?

    outputs.user = user

    # An account whose email is still unverified has no verified address we can
    # send a reset link to, and telling the user "we can't find your account"
    # is a dead end -- reset is the one flow meant to recover access. Resend
    # their email verification instead so they can finish claiming the account.
    if !logged_in_user && user.unverified?
      resend_email_verification(user)
      outputs.needs_email_verification = true
      return
    end

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

  # Login looks users up with the unfiltered `by_email_or_username`, but reset
  # historically used the verified-only `by_verified_email`, so an account with
  # an unverified email was findable at login yet invisible to reset. Try the
  # verified lookup first (an activated user always gets a real reset email),
  # then fall back to login's lookup -- but only surface the fallback when it's
  # genuinely an unverified account, so accounts in other states keep the
  # previous behaviour instead of silently resolving to an unsendable reset.
  def find_user(email)
    verified_user = LookupUsers.by_verified_email(email).first
    return verified_user if verified_user.present?

    candidate = LookupUsers.by_email_or_username(email).first
    candidate if candidate&.unverified?
  end

  def resend_email_verification(user)
    user.email_addresses.unverified.each do |email_address|
      NewflowMailer.signup_email_confirmation(email_address: email_address).deliver_later
    end
  end

  def logged_in_user
    @logged_in_user ||= !caller.is_anonymous? && caller
  end
end
