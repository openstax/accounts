# Sets the password for a user
class SetPassword

  lev_routine

  protected

  def exec(user:, password:, expiration_period: Identity::DEFAULT_PASSWORD_EXPIRATION_PERIOD)

    identity = user.identity || user.build_identity

    # Note: If `password` is blank, it will not be set on the identity object (there's a
    # check for this in ActiveModel::SecurePassword).  This leads to confusing errors
    # about the password not matching its confirmation, so error out immediately.
    fatal_error(code: :password_cannot_be_blank) if password.blank?

    identity.password = password
    identity.password_expires_at = expiration_period.nil? ? nil : DateTime.now + expiration_period

    identity.save

    outputs[:identity] = identity

    transfer_errors_from(identity, {type: :verbatim}, true)

    identity_authentication =
      user.authentications.find_by(provider: 'identity') ||
      user.authentications.create!(provider: 'identity', uid: identity.id.to_s)

    fatal_error(code: :orphaned_identity_auth) if identity_authentication.uid != identity.id.to_s
  end

end
