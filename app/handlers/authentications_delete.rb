class AuthenticationsDelete

  lev_handler

  protected

  def setup
    @auth = caller.authentications.find_by(provider: params[:provider])
  end

  def authorized?
    OSU::AccessPolicy.action_allowed?(:delete, caller, @auth)
  end

  def handle
    @auth.destroy
    outputs[:authentication] = @auth
    fatal_error(code: :cannot_delete_last_auth,
                message: (I18n.t :"handlers.authentications_delete.cannot_delete_last_authentication")) \
      unless @auth.destroyed?
  end
end
