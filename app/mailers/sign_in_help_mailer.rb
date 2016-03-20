class SignInHelpMailer < SiteMailer

  def sign_in_help(email_address, reset_password_code)
    @email_address = email_address
    @reset_password_code = reset_password_code
    @user = email_address.user
    mail to: "\"#{@user.full_name}\" <#{email_address.value}>",
         subject: "Instructions for signing in to your OpenStax account"
  end

end
