class ConfirmationMailer < SiteMailer

  def reminder(email_address)
    @email_address = email_address
    mail to: "\"#{email_address.user.guessed_full_name}\" <#{email_address.value}>",
         subject: "Reminder: please verify this email address"
  end

  def instructions(email_address)
    @email_address = email_address
    mail to: "\"#{email_address.user.guessed_full_name}\" <#{email_address.value}>",
         subject: "Please verify this email address"
  end
end
