class AddEmailToUser

  lev_routine

  uses_routine SendContactInfoConfirmation

  protected

  def exec(email_address_text, user, options={})
    email_address = EmailAddress.new(value: email_address_text)
    email_address.user = user
    email_address.verified = options[:already_verified] || false
    email_address.save

    transfer_errors_from(email_address, { scope: :email_address }, true)

    run(SendContactInfoConfirmation, email_address)
  end
end
