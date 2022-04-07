require 'addressable/uri'

module AuthenticateMethods

  def newflow_authenticate_user!
    if signed_in?
      return
    else
      store_url(url: request.url)
      redirect_to newflow_login_path(request.query_parameters)
    end
  end

  def authenticate_user!
    return if signed_in?

    # Note that the following means that users must arrive with the newflow param
    # when they arrive at the oauth_authorization path in order for them to be redirected to the
    # newflow login instead of the old login page.
    # We might want to undo this when we release the new flow.
    permitted_params = params.permit(:client_id, :signup_at, :go, :no_signup, :bpff).to_h
    redirect_to(main_app.login_path(permitted_params))
  end

  def is_admin?
    return head(:forbidden) unless current_user && current_user.is_administrator?
  end

  def authenticate_admin!
    return if current_user.is_administrator?
    return head(:forbidden) if signed_in?
    store_url
    redirect_to main_app.login_path(params.permit(:client_id).to_h)
  end

  # Doorkeeper controllers define authenticate_admin!, so we need another name
  alias_method :admin_authentication!, :authenticate_admin!
end
