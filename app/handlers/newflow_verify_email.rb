class NewflowVerifyEmail
  lev_handler

  paramify :confirm do
    attribute :pin, type: String

    validates :pin, presence: true
  end

  def authorized?
    true
  end

  # TODO: rate-limit this action here (or in the controller?)
  def handle
    email = EmailAddress.where(confirmation_pin: confirm_params.pin, verified: false).first
    # OR get the email from the user stored in the session[:unverified_user]
    # OR check both and make sure that the emails are the same? probably not necessary.
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
