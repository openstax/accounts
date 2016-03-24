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

end
