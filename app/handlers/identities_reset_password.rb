class IdentitiesResetPassword

  lev_handler

  protected

  def authorized?
    true
  end

  def handle
    fatal_error(message: 'Reset password link is invalid', code: :invalid_code,
                offending_inputs: [:code]) if params[:code].nil?
    identity = Identity.where(reset_code: params[:code]).first
    fatal_error(message: 'Reset password link is invalid', code: :invalid_code,
                offending_inputs: [:code]) if identity.nil?
    fatal_error(message: 'Reset password link has expired',
                code: :expired_code, offending_inputs: [:code]) \
      unless identity.reset_code_valid? params[:code]

    if request.post?
      identity.set_password!(params[:reset_password].try(:[], :password),
        params[:reset_password].try(:[], :password_confirmation))
      transfer_errors_from(identity, {type: :verbatim})
    end

    outputs[:identity] = identity
  end
end
