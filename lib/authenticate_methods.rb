require 'addressable/uri'

module AuthenticateMethods

  def authenticate_user!
    return if signed_in?

    store_url(url: request.url)
    redirect_to main_app.login_path(request.query_parameters)
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
