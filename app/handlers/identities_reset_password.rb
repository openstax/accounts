class IdentitiesResetPassword

  lev_handler

  uses_routine SetPassword, translations: { outputs: { type: :verbatim } }

  protected

  def authorized?
    true
  end

  def handle
    prc = PasswordResetCode.where(code: params[:code]).first
    identity = prc.try(:identity)
    fatal_error(message: 'Reset password link is invalid', code: :invalid_code,
                offending_inputs: [:code]) if identity.nil?
    fatal_error(message: 'Reset password link has expired',
                code: :expired_code, offending_inputs: [:code]) if prc.expired?

    if request.post?
      run(SetPassword,
          identity,
          params[:reset_password].try(:[], :password),
          params[:reset_password].try(:[], :password_confirmation))
    else
      outputs[:identity] = identity
    end
  end
end
