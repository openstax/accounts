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
    unverified_email_address = unverified_email_address_for(user) unless logged_in_user
    if unverified_email_address.present?
      NewflowMailer.signup_email_confirmation(email_address: unverified_email_address).deliver_later
      outputs.email_address = unverified_email_address
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
  # verified lookup first (an account with a verified address always gets a real
  # reset email), then fall back to login's lookup -- but only surface the
  # fallback when we can actually send that account somewhere, rather than
  # silently resolving to an unsendable reset.
  def find_user(email)
    verified_user = LookupUsers.by_verified_email(email).first
    return verified_user if verified_user.present?

    candidate = LookupUsers.by_email_or_username(email).first
    candidate if unverified_email_address_for(candidate).present?
  end

  # The verification flow confirms exactly one address, so only route there when
  # we can name it. Prefer the address the user typed; fall back to the account's
  # first unverified address (the lookup also matches usernames). Returns nil for
  # an account with nothing left to verify -- `ConfirmByPin` short-circuits on an
  # already-confirmed address, so sending those to the PIN form would accept any
  # PIN and sign the visitor in.
  #
  # The gate is "no verified address anywhere on the account", not `state ==
  # unverified`: an address abandoned at the PIN screen years ago squats the
  # address just as hard, whatever state its account happens to be in, and it is
  # the accounts nobody has ever proven control of that need this door. Keying on
  # verified addresses is also the stricter test -- it can never route someone
  # into an account whose owner already confirmed an address.
  def unverified_email_address_for(user)
    return if user.nil? || user.email_addresses.verified.any?

    addresses = user.email_addresses.unverified.to_a
    addresses.detect { |address| address.value.casecmp?(outputs.email.to_s) } || addresses.first
  end

  def logged_in_user
    @logged_in_user ||= !caller.is_anonymous? && caller
  end
end
