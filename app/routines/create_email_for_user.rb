class CreateEmailForUser

  lev_routine express_output: :email

  protected ###############

  def exec(email, user, options = {})
    return if email.blank?

    email = EmailAddress.find_or_create_by(value: email&.downcase, user_id: user.id)
    email.is_school_issued = options[:is_school_issued] || false

    # If the email address already exists and is attached to the user, nothing to do
    email_address = user.email_addresses.find_by(value: email)
    return if email_address.try!(:verified)

    # If it is a brand new email address, make it
    if email.nil?
      email = EmailAddress.new(value: email)
      email.user = user
      email.is_school_issued = options[:is_school_issued] || false
    end

    # This is either a new email address (unverified) or an existing email address
    # that is unverified, so verified should be false unless already verified
    email.verified = options[:already_verified] || false

    email.customize_value_error_message(
      error: :missing_mx_records,
      message: I18n.t(:"login_signup_form.invalid_email_provider", email: email)
    )

    email.save
    transfer_errors_from(email, { scope: :email }, true)

    if email.new_record? || !email.verified?
      SecurityLog.create!(
        user: user,
        event_type: :email_added_to_user,
        event_data: { email: email }
      )
      NewflowMailer.signup_email_confirmation(email_address: email).deliver_later
    end

    outputs.email = email

  end

end
