# This routine should only be used with persisted identities
# If not yet persisted, the identity will be saved by Rails
# when the PasswordResetCode is saved
class GeneratePasswordResetCode

  # This routine is serializable because it contains
  # a find_or_create for identity.password_reset_code
  # We could get rid of this by merging the identity and password_reset_code tables
  lev_routine transaction: :serializable

  protected

  def exec(identity, expiration_period = PasswordResetCode::DEFAULT_EXPIRATION_PERIOD)
    identity.build_password_reset_code if identity.password_reset_code.nil?
    prc = identity.password_reset_code
    prc.generate(expiration_period)
    prc.save

    outputs[:code] = prc.code
    outputs[:expires_at] = prc.expires_at
    transfer_errors_from prc, type: :verbatim
  end

end
