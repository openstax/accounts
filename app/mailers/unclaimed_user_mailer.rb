class UnclaimedUserMailer < SiteMailer

  def welcome(email_address)
    @email_address = email_address
    @can_log_in = email_address.user.identity.present?
    mail to: email_address.value,
         subject: "You have been invited to join OpenStax"
  end

end
