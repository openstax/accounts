class AddEmailToUser

  lev_routine

  uses_routine SendContactInfoConfirmation

  protected

  def exec(email_address_text, user, options={})
    # If no email address, nothing to do
    return if email_address_text.blank?

    # If the email address already exists and is attached to the user, nothing to do
    email_address = user.email_addresses.where(value: email_address_text).first
    return if email_address.try(:verified)

    # If it is a brand new email address, make it and send confirmation
    if email_address.nil?
      email_address = EmailAddress.new(value: email_address_text)
      email_address.user = user
      email_address.verified = options[:already_verified] || false

      email_address.save
      transfer_errors_from(email_address, { scope: :email_address }, true)

      run(SendContactInfoConfirmation, email_address)
    elsif !email_address.verified && options[:already_verified]
      email_address.verified = true
      email_address.save
      transfer_errors_from(email_address, { scope: :email_address }, true)
    end

  end
end
