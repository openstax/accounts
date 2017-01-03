class AddEmailToUser

  lev_routine

  uses_routine SendContactInfoConfirmation

  protected

  def exec(email_address_text, user, options={})
    # If no email address, nothing to do
    return if email_address_text.blank?

    # If the email address already exists and is attached to the user, nothing to do
    email_address = user.email_addresses.find_by(value: email_address_text)
    return if email_address.try(:verified)

    # If it is a brand new email address, initialize it
    email_address ||= EmailAddress.new(value: email_address_text)
    email_address.user = user

    verified = options[:already_verified]
    verified = Rails.application.secrets[:auto_verify_emails] if verified.nil?
    verified = false if verified.nil?

    email_address.verified = verified

    email_address.save
    transfer_errors_from(email_address, { scope: :email_address }, true)

    # The confirmation info won't be sent if already verified
    run(SendContactInfoConfirmation, contact_info: email_address)

    outputs.email = email_address
  end
end
