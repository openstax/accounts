class CreateEmailForUser

  lev_routine express_output: :email

  protected

  def exec(email_address_text, user, is_school_issued: nil)
    return if email_address_text.blank?

    @email = user.email_addresses.find_by(value: email_address_text.downcase)
    return if @email.try!(:verified)

    if @email.nil?
      @email = EmailAddress.new(value: email_address_text)
      @email.user = user
    end

    @email.is_school_issued = options[:is_school_issued] || false

    # This is either a new email address (unverified) or an existing email address
    # that is unverified, so verified should be false unless already verified
    @email.verified = options[:already_verified] || false

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
        event_data: { email: @email }
      )
      ConfirmationMailer.signup_email_confirmation(email_address: @email).deliver_later
    end

    outputs.email = @email

    user.contact_infos.reset
    user.email_addresses.reset
  end

end
