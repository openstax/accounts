# This routine should only be used with persisted identities
# If not yet persisted, the identity will be saved by Rails
# when the PasswordResetCode is saved
class GeneratePasswordResetCode

  lev_routine

  protected

  def exec(identity,
           expiration_period = PasswordResetCode::DEFAULT_EXPIRATION_PERIOD)
    identity.password_reset_code ||= identity.build_password_reset_code
    prc = identity.password_reset_code
    prc.generate(expiration_period)
    prc.save

    outputs[:code] = prc.code
    outputs[:expires_at] = prc.expires_at
    transfer_errors_from prc, type: :verbatim
  end

end
