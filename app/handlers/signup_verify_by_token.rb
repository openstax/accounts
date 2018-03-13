class SignupVerifyByToken

  lev_handler

  uses_routine ConfirmByCode,
               translations: { outputs: { map: { contact_info: :pre_auth_state } },
                               inputs: { type: :verbatim } }
  uses_routine SignupExternalStudent, translations: { outputs: { type: :verbatim } }

  protected

  def authorized?
    true
  end

  def handle
    run(ConfirmByCode, params[:code])

    if outputs[:pre_auth_state].try!(:signed_student?)
      run(SignupExternalStudent, pre_auth_state: outputs[:pre_auth_state], already_verified: true)
      options[:session].sign_in!(outputs.user)
    end
  end

end
