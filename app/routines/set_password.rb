# Sets the password for a given Identity object
class SetPassword

  lev_routine

  protected

  def exec(identity,
           password,
           password_confirmation = nil,
           expiration_period = Identity::DEFAULT_PASSWORD_EXPIRATION_PERIOD)
    identity.password = password
    identity.password_confirmation = password_confirmation

    # Reset the expiration period
    identity.password_expires_at = \
      expiration_period.nil? ? nil : DateTime.now + expiration_period

    # Invalidate reset code if it exists
    identity.password_reset_code.try(:expire)

    identity.save

    outputs[:identity] = identity

    transfer_errors_from identity, type: :verbatim
  end

end
