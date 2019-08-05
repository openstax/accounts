class SignupStart

  lev_handler

  paramify :signup do
    attribute :email, type: String
    validates :email, presence: true
    attribute :role, type: String
    validates :role, presence: true
  end

  def authorized?
    true
  end

  def handle
    if !User.known_roles.include?(signup_params.role)
      fatal_error(code: :unknown_role, offending_inputs: [:signup, :role])
    end
    outputs.role = signup_params.role

    # If email in use, want users to login with that email, not create another account
    fatal_error(code: :email_in_use, offending_inputs: [:signup, :email]) if email_in_use?

    fatal_error(code: :invalid, offending_inputs: [:signup, :email]) if invalid_email?

    # is there a pre_auth_state and it's email is unchanged
    if existing_pre_auth_state.try(:contact_info_value) == email
      existing_pre_auth_state.update_attributes(role: signup_params.role)
      outputs.pre_auth_state = existing_pre_auth_state
      # pre_auth_state may have been created in session start
      # and the the confirmation email will not yet have been sent
      deliver_validation_email if existing_pre_auth_state.confirmation_sent_at.nil?
      return
    end

    # Create a new one
    new_pre_auth_state = PreAuthState.email_address.create(
      is_partial_info_allowed: false,
      contact_info_value: email,
      role: signup_params.role,
      signed_data: existing_pre_auth_state.try!(:signed_data),
      return_to: options[:return_to]
    )

    # Blow away the user's existing signup email, if it exists
    existing_pre_auth_state.try(:destroy)

    transfer_errors_from(new_pre_auth_state,
                         { map: { contact_info_value: :email },
                           scope: :signup },
                         true)


    outputs.pre_auth_state = new_pre_auth_state
    deliver_validation_email # Send the pin
  end

  def deliver_validation_email
    SignupConfirmationMailer.instructions(
      pre_auth_state: outputs.pre_auth_state
    ).deliver_later
  end

  def email
    signup_params.email.strip
  end

  def email_in_use?
    ContactInfo.verified.where('lower(value) = ?', email.downcase).any?
  end

  def invalid_email?
    e = EmailAddress.new(value: email)

    begin
      e.mx_domain_validation
      return e.errors.any?
    rescue Mail::Field::IncompleteParseError
      return true
    end
  end

  def existing_pre_auth_state
    options[:existing_pre_auth_state]
  end

end
