# Sets the password for a user
class SetPassword

  lev_routine

  protected

  def exec(user:,
           password:,
           password_confirmation:,
           expiration_period: Identity::DEFAULT_PASSWORD_EXPIRATION_PERIOD)

    identity = user.identity || user.build_identity

    # Note: If `password` is blank, it will not be set on the identity object (there's a
    # check for this in ActiveModel::SecurePassword).  This leads to confusing errors
    # about the password not matching its confirmation, so error out immediately.

    fatal_error(code: :password_cannot_be_blank) if password.blank?

    identity.password = password
    identity.password_confirmation = password_confirmation
    identity.password_expires_at = \
      expiration_period.nil? ? nil : DateTime.now + expiration_period

    identity.save

    outputs[:identity] = identity

    transfer_errors_from(identity, {type: :verbatim}, true)

    # If the user does not have an authentication for an identity then we create once
    unless user.authentications.where(provider: 'identity').any?
      user.authentications.create!(provider: 'identity', uid: identity.id.to_s)
    end
  end

end
