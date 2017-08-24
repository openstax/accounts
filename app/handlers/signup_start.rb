class SignupStart

  lev_handler

  paramify :signup do
    attribute :email, type: String
    validates :email, presence: true
    attribute :role, type: String
    validates :role, presence: true
  end

  uses_routine ConfirmContactInfo

  def authorized?
    true
  end

  def handle
    if !User.known_roles.include?(signup_params.role)
      fatal_error(code: :unknown_role, offending_inputs: [:signup, :role])
    end
    outputs.redirect_action = :verify_email
    outputs.role = signup_params.role

    # Return if user went back, didn't change anything, and resubmitted
    if existing_signup_state.try(:contact_info_value) == email
      existing_signup_state.update_attributes(role: signup_params.role)
      outputs.signup_state = existing_signup_state
      if trusted_state && trusted_state['email'] == email
        confirm_trusted_account(existing_signup_state)
      end
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
                         { map: { contact_info_value: :email },
                           scope: :signup },
                         true)

    # Send the pin
    SignupConfirmationMailer.instructions(
      signup_state: new_signup_state
    ).deliver_later

    outputs.signup_state = new_signup_state
  end

  def confirm_trusted_account(signup_state)
    user = User.create
    user.role = signup_state.role
    user.full_name = trusted_state['name']
    user.save

    transfer_errors_from(user, {type: :verbatim}, true)
    ci = user.contact_infos.build(
      type: 'EmailAddress',
      value: signup_state.contact_info_value
    )
    run(ConfirmContactInfo, ci)
    transfer_errors_from(ci, {type: :verbatim}, true)
    options[:session].sign_in! user

    uuid = UserAlternativeUuid.create(user: user, uuid: trusted_state['uuid'])
    transfer_errors_from(uuid, {type: :verbatim}, true)

    outputs.redirect_action = :password
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

  def trusted_state
    options[:trusted_state]
  end
end
