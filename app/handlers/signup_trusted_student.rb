class SignupTrustedStudent

  lev_handler

  uses_routine AddEmailToUser,
               translations: { inputs:  {scope: :signup},
                               outputs: {type: :verbatim}  }

  uses_routine UserFromSignupState,
               translations: { inputs:  {scope: :signup},
                               outputs: {type: :verbatim}  }

  def authorized?
    signup_state.trusted?
  end

  def handle
    run(UserFromSignupState, signup_state)
    run(AddEmailToUser, signup_state.contact_info_value, outputs.user, {already_verified: true})
    options[:session].sign_in!(outputs.user)
  end

  def signup_state
    options[:signup_state]
  end
end
