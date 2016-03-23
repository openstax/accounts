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
      fatal_error(code: :user_not_found,
                  message: 'We did not find an account with the username or email you provided.',
                  offending_inputs: [:username])
    end
    email_addresses = user.contact_infos.email_addresses
    if email_addresses.empty?
      fatal_error(code: :no_email_addresses,
                  message: "We found your account but can't send you an email because your " \
                           "account doesn't have any email addresses listed.  Please contact " \
                           "support for assistance.",
                  offending_inputs: [:email_address])
    end
    code = run(GeneratePasswordResetCode, user.identity).outputs[:code] \
      unless user.identity.nil?
    SignInHelpMailer.sign_in_help(email_addresses.first, code).deliver
  end
end
