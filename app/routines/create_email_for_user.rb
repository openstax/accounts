class CreateEmailForUser

  lev_routine

  protected

  def exec(email:, user:, is_school_issued: nil)
    @email = EmailAddress.find_or_create_by(value: email&.downcase, user_id: user.id)
    @email.is_school_issued = is_school_issued

    @email.customize_value_error_message(
      error: :missing_mx_records,
      message: I18n.t(:"login_signup_form.invalid_email_provider", email: @email.value)
    )
    transfer_errors_from(@email, { scope: :email }, :fail_if_errors)

    if @email.new_record? || !@email.verified?
      SecurityLog.create!(
        user: user,
        event_type: :email_added_to_user,
        event_data: { email: @email }
      )
      ConfirmationMailer.signup_email_confirmation(email_address: @email).deliver_later
    end

    @email.save
  end

end
