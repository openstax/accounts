class IdentitiesUpdate

  lev_handler

  paramify :identity do
    attribute :password, type: String
    attribute :password_confirmation, type: String
  end

  protected

  def setup
    @identity = caller.identity || caller.build_identity
  end

  def authorized?
    OSU::AccessPolicy.action_allowed?(:update, caller, @identity)
  end

  def handle
    @identity.password = identity_params.password
    @identity.password_confirmation = identity_params.password_confirmation
    @identity.save
    outputs[:identity] = @identity

    transfer_errors_from(@identity, {scope: :identity}, true)

    # If the user does not have an authentication for an identity then we create once
    unless caller.authentications.where(provider: 'identity').any?
      caller.authentications.create!(provider: 'identity', uid: @identity.id.to_s)
    end

  end
end
