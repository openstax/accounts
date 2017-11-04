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

    # is there a signup_state and it's email is unchanged
    if existing_signup_state.try(:contact_info_value) == email
      existing_signup_state.update_attributes(role: signup_params.role)
      outputs.signup_state = existing_signup_state
      # signup_state may have beenn created in session start
      # and the the confirmation email will not yet have been sent
      deliver_validation_email if existing_signup_state.confirmation_sent_at.nil?
      return
    end

    # If email in use, want users to login with that email, not create another account
    fatal_error(code: :email_in_use, offending_inputs: [:signup, :email]) if email_in_use?

    # Create a new one
    new_signup_state = SignupState.email_address.create(
      contact_info_value: email,
      role: signup_params.role,
      trusted_data: existing_signup_state.try(:trusted_data),
      return_to: options[:return_to]
    )

    # Blow away the user's existing signup email, if it exists
    existing_signup_state.try(:destroy)

    transfer_errors_from(new_signup_state,
                         { map: { contact_info_value: :email },
                           scope: :signup },
                         true)


    outputs.signup_state = new_signup_state
    deliver_validation_email # Send the pin

  end

  def deliver_validation_email
    SignupConfirmationMailer.instructions(
      signup_state: outputs.signup_state
    ).deliver_later
  end

  def email
    signup_params.email.strip
  end

  def email_in_use?
    ContactInfo.verified.where('lower(value) = ?', email.downcase).any?
  end

  def existing_signup_state
    options[:existing_signup_state]
  end

end
