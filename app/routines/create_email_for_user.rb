class CreateEmailForUser

  lev_routine express_output: [:email, :contact_infos]

  protected

  def exec(email_address_text, user, is_school_issued: false, already_verified: false)
    return if email_address_text.blank?


    email_address = user.email_addresses.find_by(value: email_address_text.downcase)
    return if email_address.try!(:verified)

    if email_address.nil?
      email_address = EmailAddress.new(value: email_address_text)
      email_address.user = user
    end

    email_address.is_school_issued = is_school_issued

    # This is either a new email address (unverified) or an existing email address
    # that is unverified, so verified should be false unless already verified
    email_address.verified = already_verified

    email_address.customize_value_error_message(
      error:   :missing_mx_records,
      message: I18n.t(:'login_signup_form.invalid_email_provider', email: email_address_text)
    )

    email_address.save
    transfer_errors_from(email_address, { scope: :email }, true)

    if email_address.new_record? || !email_address.verified?
      SecurityLog.create!(
        user:       user,
        event_type: :email_added_to_user,
        event_data: { email: email_address_text }
      )
      NewflowMailer.signup_email_confirmation(email_address: email_address).deliver_later
    end

    contact_info = ContactInfo.find_or_create_by(value: email_address_text, type: 'EmailAddress')

    outputs.email = email_address
    outputs.contact_info = contact_info

    user.contact_infos.reset
    user.email_addresses.reset
  end

end
