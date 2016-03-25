class IdentitiesUpdate

  lev_handler

  paramify :identity do
    attribute :current_password, type: String
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
    @identity.set(identity_params.as_hash(:password, :password_confirmation))
    @identity.save!
    # If the user does not have an authentication for an identity then we create once
    unless caller.authentications.where(provider: 'identity').any?
      caller.authentications.create!(provider: 'identity', uid: @identity.id.to_s)
    end

    outputs[:identity] = @identity
    transfer_errors_from(@identity, {scope: :identity})
  end
end
