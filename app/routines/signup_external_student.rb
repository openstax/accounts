class SignupExternalStudent

  lev_routine express_output: :user

  uses_routine AddEmailToUser, translations: { outputs: {type: :verbatim}  }
  uses_routine UserFromSignupState, translations: { outputs: {type: :verbatim}  }

  protected

  def exec(signup_state:, already_verified: false)
    run(UserFromSignupState, signup_state)
    run(
      AddEmailToUser, signup_state.contact_info_value,
      outputs.user, already_verified: already_verified
    )
  end

end
