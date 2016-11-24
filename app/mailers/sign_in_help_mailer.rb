class SignInHelpMailer < SiteMailer

  def sign_in_help(user:, email_address:, reset_password_code: nil,
                   multiple_emails_per_user: false, multiple_users: false)
    @user = user
    @reset_password_code = reset_password_code
    @multiple_emails_per_user = multiple_emails_per_user
    @multiple_users = multiple_users

    mail to: "\"#{@user.full_name}\" <#{email_address}>",
         subject: "Instructions for signing in to your OpenStax account"
  end

  def multiple_accounts(email_address:, usernames:)
    @email_address = email_address
    @usernames = usernames

    mail to: email_address,
         subject: "Your OpenStax usernames"
  end

  def reset_password(user:, email_address:)
    @user = user

    raise "No valid login token" if user.login_token.nil? || user.login_token_expired?

    mail to: "\"#{user.full_name}\" <#{email_address}>",
         subject: "Reset your OpenStax password"
  end

  def add_password(user:, email_address:)
    @user = user

    raise "No valid login token" if user.login_token.nil? || user.login_token_expired?

    mail to: "\"#{user.full_name}\" <#{email_address}>",
         subject: "Add a password to your OpenStax account"
  end

end
