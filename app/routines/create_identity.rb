# Creates an identity with the supplied parameters.
#
#
class CreateIdentity

  lev_routine

  protected

  def identity_params(inputs)
    ActionController::Parameters.new(inputs).permit(:password, :password_confirmation, :user_id)
  end

  def exec(inputs={})
    outputs[:identity] = Identity.create(identity_params(inputs))

    transfer_errors_from(outputs[:identity],{type: :verbatim})
  end

end
