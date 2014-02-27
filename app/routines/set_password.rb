class SetPassword

  include Lev::Routine

protected

  def exec(identity, password, password_confirmation)
    identity.password = password
    identity.password_confirmation = password_confirmation
    identity.save

    transfer_errors_from(identity, scope: :password)
  end
end
