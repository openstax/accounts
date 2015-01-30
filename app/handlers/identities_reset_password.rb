class IdentitiesResetPassword

  lev_handler

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
      identity.set_password(params[:reset_password].try(:[], :password),
        params[:reset_password].try(:[], :password_confirmation))
      identity.save
      transfer_errors_from(identity, {type: :verbatim})
    end

    outputs[:identity] = identity
  end
end
