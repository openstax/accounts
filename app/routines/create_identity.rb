# Creates an identity with the supplied parameters.
class CreateIdentity

  lev_routine

  protected

  def exec(inputs={})
    outputs[:identity] = Identity.create do |identity|
      identity.password = inputs[:password]
      identity.password_confirmation = inputs[:password_confirmation]
      identity.user_id = inputs[:user_id]
    end

    transfer_errors_from(outputs[:identity],{type: :verbatim})
  end

end
