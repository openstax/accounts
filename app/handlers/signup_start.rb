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

    # Return if user went back, didn't change anything, and resubmitted
    if existing_signup_state.try(:contact_info_value) == email
      outputs.signup_state = existing_signup_state
      return
    end

    # If email in use, want users to login with that email, not create another account
    fatal_error(code: :email_in_use, offending_inputs: [:signup, :email]) if email_in_use?

    # Blow away the user's existing signup email, if it exists
    existing_signup_state.try(:destroy)

    # Create a new one
    new_signup_state = SignupState.email_address.create(contact_info_value: email,
                                                        role: signup_params.role,
                                                        return_to: options[:return_to])

    transfer_errors_from(new_signup_state,
                         { map: { contact_info_value: :email }, scope: :signup },
                         true)

    # Send the pin
    SignupConfirmationMailer.instructions(
      signup_state: new_signup_state
    ).deliver_later

    outputs.signup_state = new_signup_state
  end

  def email
    signup_params.email.strip
  end

  def email_in_use?
    ContactInfo.verified.where(value: email).any?
  end

  def existing_signup_state
    options[:existing_signup_state]
  end
end
