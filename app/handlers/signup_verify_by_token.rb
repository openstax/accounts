class SignupVerifyByToken

  lev_handler

  uses_routine ConfirmByCode,
               translations: { outputs: { map: { contact_info: :signup_state } },
                               inputs: { type: :verbatim } }

  protected

  def authorized?
    true
  end

  def handle
    run(ConfirmByCode, params[:code])
  end

end
