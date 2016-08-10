class AuthenticationsDelete

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
    fatal_error(code: :cannot_delete_last_auth,
                message: "Cannot delete an activated user's last authentication") \
      unless @auth.destroyed?
  end
end
