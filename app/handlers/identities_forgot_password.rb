class IdentitiesForgotPassword

  lev_handler

  uses_routine GeneratePasswordResetCode

  paramify :forgot_password do
    attribute :username_or_email, type: String
    validates :username_or_email, presence: true
  end

  protected

  def authorized?
    true
  end

  def handle
    username_or_email = forgot_password_params.username_or_email
    user = User.find_by_username(username_or_email) ||
           ContactInfo.find_by_value(username_or_email).try(:user)
    if user.nil?
      fatal_error(code: (I18n.t :"handlers.identities_forgot_password.username_not_found"),
                  offending_inputs: [:username])
    end
    if user.identity.nil?
      fatal_error(code: (I18n.t :"handlers.identities_forgot_password.unable_to_reset_password"),
                  offending_inputs: [:identity])
    end
    email_addresses = user.contact_infos.email_addresses.verified
    if email_addresses.empty?
      fatal_error(code: (I18n.t :"handlers.identities_forgot_password.no_verified_emails"),
                  offending_inputs: [:email_address])
    end
    code = run(GeneratePasswordResetCode, user.identity).outputs[:code]
    ResetPasswordMailer.reset_password(email_addresses.first, code).deliver
  end
end
