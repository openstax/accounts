class ResetPasswordMailer < SiteMailer

  def reset_password(email_address, reset_password_code)
    @email_address = email_address
    @reset_password_code = reset_password_code
    mail to: "\"#{email_address.user.full_name}\" <#{email_address.value}>",
         subject: "Reset your password"
  end

end
