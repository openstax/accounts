class NewflowVerifyEmail
  lev_handler
  uses_routine ConfirmByPin

  paramify :confirm do
    attribute :pin, type: String

    validates :pin, presence: true
  end

  def authorized?
    true
  end

  # TODO: rate-limit this action here (or in the controller?)
  def handle
    result = ConfirmByPin.call(contact_info: options[:email_address], pin: confirm_params.pin)
    if result.errors.any?
      fatal_error(
        code: :invalid_confirmation_pin,
        offending_inputs: [:pin],
        message: I18n.t(:"login_signup_form.invalid_confirmation_pin")
      )
    end

    claiming_user = options[:email_address].user
    claiming_user.update(state: 'activated')

    outputs.user = claiming_user
  end
end
