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
    identity_attributes = identity_params.as_hash(:password,
                                                  :password_confirmation)

    # This may be better moved elsewhere, but we'll do so here since it doesn't make
    # sense to set the password of a identity that won't work without an authentication
    unless caller.authentications.where(provider: 'identity').any?
      caller.authentications.create!(provider: 'identity', uid: caller.id)
    end

    @identity.update_attributes(identity_attributes)
    outputs[:identity] = @identity
    transfer_errors_from(@identity, {scope: :identity})
  end
end
