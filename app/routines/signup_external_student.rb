class SignupExternalStudent

  lev_routine express_output: :user

  uses_routine AddEmailToUser, translations: { outputs: {type: :verbatim}  }

  protected

  def exec(email:, already_verified: false)
    run(
      AddEmailToUser, email,
      outputs.user, already_verified: already_verified
    )
  end

end
