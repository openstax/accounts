class SignupExternalStudent

  lev_routine express_output: :user

  uses_routine AddEmailToUser, translations: { outputs: {type: :verbatim}  }
  uses_routine UserFromSignupState, translations: { outputs: {type: :verbatim}  }

  protected

  def exec(signup_state)
    run(UserFromSignupState, signup_state)
    run(AddEmailToUser, signup_state.contact_info_value, outputs.user, {already_verified: true})
  end

end
