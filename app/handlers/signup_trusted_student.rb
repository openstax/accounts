class SignupTrustedStudent

  lev_handler

  uses_routine UserFromSignupState,
               translations: { inputs:  {scope: :signup},
                               outputs: {type: :verbatim}  }

  def authorized?
    signup_state.trusted?
  end

  def handle
    run(UserFromSignupState, signup_state)
    contact_info = ContactInfo.new(type: 'EmailAddress', value: signup_state.contact_info_value)
    contact_info.verified = true
    contact_info.user = outputs.user
    contact_info.save
    transfer_errors_from(contact_info, {scope: :contact_info}, true)
    options[:session].sign_in!(outputs.user)
  end

  def signup_state
    options[:signup_state]
  end
end
