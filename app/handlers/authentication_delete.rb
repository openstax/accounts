class AuthenticationDelete

  lev_handler

  protected

  def setup
    @auth = caller.authentications.find_by_provider(params[:provider])
  end

  def authorized?
    OSU::AccessPolicy.action_allowed?(:delete, caller, @auth)
  end

  def handle
    @auth.destroy
    outputs[:authentication] = @auth
    transfer_errors_from(@auth, {scope: :authentication})
  end
end
