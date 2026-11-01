# Marks an `EmailAddress` as `verified` if it matches the passed-in `EmailAddress`'s pin
# and then marks the owner of the email address as 'activated'.
class VerifyUserEmailByPin

  def handle
    email_address = options[:email_address]
    result = ConfirmByPin.call(contact_info: email_address, pin: normalized_pin)
    fail_confirmation(result.errors.map(&:code), email_address) if result.errors.any?

    claiming_user = email_address.user
    activate_user(claiming_user)
    outputs.user = claiming_user
  end

  def activate_user(claiming_user)
    raise('Must implement')
  end

  private

  # The PIN is six digits, but people paste it from the subject line or type it
  # as "123 456"; anything that isn't a digit can never be part of it.
  def normalized_pin
    confirm_params.pin.to_s.gsub(/\D/, '')
  end

  def fail_confirmation(codes, email_address)
    # Once the attempts run out even the right PIN is refused, so saying
    # "incorrect" sends the user round in circles. Point them at the link in
    # the email instead, which still works.
    if codes.include?(:no_pin_confirmation_attempts_remaining)
      fatal_error(
        code: :no_pin_confirmation_attempts_remaining,
        offending_inputs: [:pin],
        message: I18n.t(:"login_signup_form.pin_attempts_exhausted")
      )
    end

    # ConfirmByPin counts a wrong PIN, but that write joins this handler's
    # transaction and the fatal_error below rolls it back -- so the PIN form
    # never counted a miss and the attempt limit never applied. Count it again
    # once the rollback is done.
    after_transaction { ConfirmByPin.sequential_failure_for(email_address).increment! }

    fatal_error(
      code: :invalid_confirmation_pin,
      offending_inputs: [:pin],
      message: I18n.t(:"login_signup_form.pin_not_correct")
    )
  end

end
