class SignupVerifyEmail

  lev_handler

  uses_routine ConfirmByPin
  uses_routine ConfirmByCode,
               translations: { outputs: { type: :verbatim },
                               inputs: { type: :verbatim } }

  paramify :confirm do
    attribute :pin, type: String
    attribute :code, type: String
  end

  def authorized?
    true
  end

  def handle

    if confirm_params.pin
      run(ConfirmByPin pin: confirm_params.pin)

      result = ConfirmByPin.call(contact_info: options[:email_address], pin: confirm_params.pin)
      if result.errors.any?
        fatal_error(
          code: :invalid_confirmation_pin,
          offending_inputs: [:pin],
          message: I18n.t(:"login_signup_form.pin_not_correct")
        )
      end

      user = options[:email_address].user
    elsif confirm_params.code
      run(ConfirmByCode, confirm_params.code)

      user = outputs.contact_info.user
    end

    run(ActivateUser, user: user, role: user.role)

    outputs.user = user
  end
end
