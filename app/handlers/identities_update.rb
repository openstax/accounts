class IdentitiesUpdate

  lev_handler

  paramify :identity do
    attribute :current_password, type: String
    attribute :password, type: String
    attribute :password_confirmation, type: String
  end

  protected

  def setup
    @identity = caller.identity
  end

  def authorized?
    OSU::AccessPolicy.action_allowed?(:update, caller, @identity)
  end

  def handle
    identity_attributes = identity_params.as_hash(:password,
                                                  :password_confirmation)
    @identity.update_attributes(identity_attributes)
    outputs[:identity] = @identity
    transfer_errors_from(@identity, {scope: :identity})
  end
end
