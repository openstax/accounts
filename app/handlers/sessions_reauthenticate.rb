class SessionsReauthenticate

  lev_handler

  uses_routine GetLoginInfo,
               translations: { outputs: { type: :verbatim } }

  def authorized?
    !caller.is_anonymous?
  end

  def handle
    run(GetLoginInfo, user: caller)
  end
end
