module Newflow
  # Marks an `EmailAddress` as `verified` if it matches the passed-in `EmailAddress`'s pin
  # and then marks the owner of the email address as 'activated'.
  class VerifyUserEmailByPin

    def handle
      result = ConfirmByPin.call(contact_info: options[:email_address], pin: confirm_params.pin)
      if result.errors.any?
        fatal_error(
          code: :invalid_confirmation_pin,
          offending_inputs: [:pin],
          message: I18n.t(:"login_signup_form.pin_not_correct")
        )
      end

      claiming_user = options[:email_address].user
      activate_user(claiming_user)
      outputs.user = claiming_user
    end

    def activate_user(claiming_user)
      raise('Must implement')
    end

  end
end
