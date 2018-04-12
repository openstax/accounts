class SignupExternalStudent

  lev_routine express_output: :user

  uses_routine AddEmailToUser, translations: { outputs: {type: :verbatim}  }
  uses_routine UserFromPreAuthState, translations: { outputs: {type: :verbatim}  }

  protected

  def exec(pre_auth_state:, already_verified: false)
    run(UserFromPreAuthState, pre_auth_state)
    run(
      AddEmailToUser, pre_auth_state.contact_info_value,
      outputs.user, already_verified: already_verified
    )
  end

end
