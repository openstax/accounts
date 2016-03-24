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
    multiple_users = matching_users.count > 1

    matching_users.each do |matching_user|
      user = matching_user[:user]

      code = run(GeneratePasswordResetCode, user.identity).outputs[:code] \
        unless user.identity.nil?

      email_addresses = matching_user[:email_addresses]

      email_addresses.each do |email_address|
        SignInHelpMailer.sign_in_help(
          user: user,
          email_address: email_address,
          reset_password_code: code,
          multiple_emails_per_user: email_addresses.count > 1,
          multiple_users: matching_users.count > 1
        ).deliver
      end
    end
  end

  def matching_users
    if @matching_users.nil?
      username_or_email = help_params.username_or_email.strip

      @matching_users = matching_users_by_username(username_or_email) ||
                        matching_users_by_email(username_or_email)

      if @matching_users.blank?
        fatal_error(code: :user_not_found,
                    message: 'We did not find an account with the username or email you provided.',
                    offending_inputs: [:username_or_email])
      end
    end

    @matching_users
  end

  def matching_users_by_username(username)
    user = User.find_by_username(username)

    return nil if user.nil?

    email_addresses = user.contact_infos.email_addresses.map(&:value)

    if email_addresses.empty?
      fatal_error(code: :no_email_addresses,
                  message: "We found your account but can't send you an email because your " \
                           "account doesn't have any email addresses listed.  Please contact " \
                           "support for assistance.",
                  offending_inputs: [:email_address])
    end

    [{
      user: user,
      email_addresses: email_addresses
    }]
  end

  def matching_users_by_email(email)
    users = ContactInfo.where(value: email).all.collect(&:user)

    return nil if users.none?

    users.collect do |user|
      {
        user: user,
        email_addresses: [email]
      }
    end
  end
end
