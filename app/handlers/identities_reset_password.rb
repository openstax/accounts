class IdentitiesResetPassword

  include Lev::Handler

  uses_routine SetPassword

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
    if identity.reset_code_expires_at && identity.reset_code_expires_at <= DateTime.now
      fatal_error(message: 'Reset password link has expired', code: :expired_code,
                  offending_inputs: [:code])
    end
    if request.post?
      run(SetPassword, identity,
          params[:reset_password].try(:[], :password),
          params[:reset_password].try(:[], :password_confirmation))
      identity.use_reset_code params[:code] if errors.empty?
    end
  end
end
