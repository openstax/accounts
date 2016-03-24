class ConfirmationMailer < SiteMailer

  def instructions(email_address)
    @email_address = email_address
    mail to: "\"#{email_address.user.full_name}\" <#{email_address.value}>",
         subject: "Please verify this email address"
  end
end
