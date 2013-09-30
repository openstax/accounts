class ConfirmationMailer < SiteMailer

  def reminder(email_address)
    @email_address = email_address
    mail to: "#{email_address.user.full_name} <#{email_address.value}>",
         subject: "Reminder: please confirm this email address"
  end

  def instructions(email_address)
    @email_address = email_address
    mail to: "#{email_address.user.full_name} <#{email_address.value}>",
         subject: "Please confirm this email address"
  end
end
