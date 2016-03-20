class SessionsHelp

  lev_handler

  uses_routine GeneratePasswordResetCode

  paramify :help do
    attribute :username_or_email, type: String
    validates :username_or_email, presence: true
  end

  protected

  def authorized?
    true
  end

  def handle
    username_or_email = help_params.username_or_email.strip
    user = User.find_by_username(username_or_email) ||
           ContactInfo.find_by_value(username_or_email).try(:user)
    if user.nil?
      fatal_error(code: 'Username not found',
                  offending_inputs: [:username])
    end
    email_addresses = user.contact_infos.email_addresses
    if email_addresses.empty?
      fatal_error(code: 'No email addresses found for this user',
                  offending_inputs: [:email_address])
    end
    code = run(GeneratePasswordResetCode, user.identity).outputs[:code] \
      unless user.identity.nil?
    SignInHelpMailer.sign_in_help(email_addresses.first, code).deliver
  end
end
