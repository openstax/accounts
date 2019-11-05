class NewflowVerifyEmail
  lev_handler

  paramify :confirm do
    attribute :pin, type: String

    validates :pin, presence: true
  end

  def authorized?
    true
  end

  def handle
    email = EmailAddress.where(confirmation_pin: confirm_params.pin).first
    if email
      email.update_attributes(verified: true)
      email.user.update_attributes(state: 'activated')
      outputs.user = email.user
    else
      fatal_error(
        code: :invalid_confirmation_pin,
        offending_inputs: [:pin],
        message: I18n.t(:"login_signup_form.invalid_confirmation_pin")
      )
    end
  end
end
