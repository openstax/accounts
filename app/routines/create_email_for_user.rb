class CreateEmailForUser

  lev_routine express_output: :email

  protected

  def exec(email, user, options = {})
    return if email.blank?

    email = email&.downcase

    # initialize options we expect
    options[:is_school_issued] ||= false
    options[:already_verified] ||= false

    email = EmailAddress.find_or_create_by(value: email, user_id: user.id)

    email.is_school_issued = options[:is_school_issued]

    # This is either a new email address (unverified) or an existing email address
    # that is unverified, so verified should be false unless already verified
    email.verified = options[:already_verified]

    email.customize_value_error_message(
      error:   :missing_mx_records,
      message: I18n.t(:'login_signup_form.invalid_email_provider', email: email)
    )

    email.save
    transfer_errors_from(email, { scope: :email }, true)

    if email.new_record? || !email.verified?
      SecurityLog.create!(
        user:       user,
        event_type: :email_added_to_user,
        event_data: { email: email }
      )
      SignupPasswordMailer.signup_email_confirmation(email_address: email).deliver_later
    end

    outputs.email = email

    user.contact_infos.reset
    user.email_addresses.reset

  end

end
