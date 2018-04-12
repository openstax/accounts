class UnclaimedUserMailer < ApplicationMailer

  def welcome(email_address)
    @email_address = email_address

    mail to: email_address.value,
         subject: "You have been invited to join OpenStax"
  end

end
