class IdentitiesForgotPassword

  lev_handler

  paramify :forgot_password do
    attribute :username, type: String
    validates :username, presence: true
  end

  protected

  def authorized?
    true
  end

  def handle
    username = forgot_password_params.username
    user = User.find_by_username(username)
    if user.nil?
      fatal_error(code: 'Username not found',
                  offending_inputs: [:username])
    end
    if user.identity.nil?
      fatal_error(code: 'Unable to reset password for this user',
                  offending_inputs: [:identity])
    end
    email_addresses = user.contact_infos.email_addresses.verified
    if email_addresses.empty?
      fatal_error(code: 'No verified email addresses found for this user',
                  offending_inputs: [:email_address])
    end
    code = user.identity.generate_reset_code!
    ResetPasswordMailer.reset_password(email_addresses.first, code).deliver
  end
end
