# Sets the password for a user
class SetPassword

  lev_routine

  protected

  def exec(user:,
           password:,
           password_confirmation:,
           expiration_period: Identity::DEFAULT_PASSWORD_EXPIRATION_PERIOD)

    identity = user.identity || user.build_identity

    fatal_error(code: :no_password_to_change) if identity.nil?

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
