class CreateEmailForUser

  lev_routine

  protected

  def exec(email_address_text, user, is_school_issued: false, already_verified: false)
    return if email_address_text.blank?

    @email = EmailAddress.find_or_create_by(value: email_address_text&.downcase, user_id: user.id)
    @email.is_school_issued = is_school_issued

    # This is either a new email address (unverified) or an existing email address
    # that is unverified, so verified should be false unless already verified
    @email.verified = already_verified

    @email.customize_value_error_message(
      error:   :missing_mx_records,
      message: I18n.t(:'login_signup_form.invalid_email_provider', email: email_address_text)
    )

    @email.save
    transfer_errors_from(@email, { scope: :email }, true)

    if @email.new_record? || !@email.verified?
      SecurityLog.create!(
        user:       user,
        event_type: :email_added_to_user,
        event_data: { email: email_address_text }
      )
      NewflowMailer.signup_email_confirmation(email_address: @email).deliver_later
    end

    ContactInfo.find_or_create_by(value: email_address_text, type: 'EmailAddress', user: user)


    outputs.email = @email
    @email.save

    user.email_addresses.reset
    user.contact_infos.reset
  end

end
