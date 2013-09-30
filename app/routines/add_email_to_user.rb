
class AddEmailToUser

  include Lev::Routine

  uses_routine SendConfirmationEmail

protected

  def exec(email_address_text, user, options={})

    options[:already_verified] ||=false

    email_address = EmailAddress.create(
      value: email_address_text,
      user_id: user.id,
      verified: options[:already_verified],
      confirmation_code: options[:already_verified] ? nil : SecureRandom.hex(10)
    )

    transfer_errors_from(email_address, {scope: :email_address})

    run(SendConfirmationEmail, email_address)

  end
end
