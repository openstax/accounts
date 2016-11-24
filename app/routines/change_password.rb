# Sets the password for a user
class ChangePassword

  lev_routine

  protected

  def exec(user:,
           password:,
           password_confirmation:,
           expiration_period: Identity::DEFAULT_PASSWORD_EXPIRATION_PERIOD)

    identity = user.identity

    fatal_error(code: :no_password_to_change) if identity.nil?

    identity.password = password
    identity.password_confirmation = password_confirmation
    identity.password_expires_at = \
      expiration_period.nil? ? nil : DateTime.now + expiration_period

    identity.save

    outputs[:identity] = identity

    transfer_errors_from(identity, {type: :verbatim}, true)
  end

end
