# This routine should only be used with persisted identities
# If not yet persisted, the identity will be saved by Rails
# when the PasswordResetCode is saved
class GenerateResetCode

  lev_routine

  protected

  def exec(identity, expiration_period = ResetCode::DEFAULT_EXPIRATION_PERIOD)
    identity.reset_code ||= identity.build_reset_code
    rc = identity.reset_code
    rc.generate(expiration_period)
    rc.save

    outputs[:code] = rc.code
    outputs[:expires_at] = rc.expires_at
    transfer_errors_from rc, type: :verbatim
  end

end
