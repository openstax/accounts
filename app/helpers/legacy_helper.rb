module LegacyHelper

  def redirect_to_newflow_if_enabled
    return unless request.get?
    if request.path == signup_path
      redirect_to newflow_signup_path(request.query_parameters)
    elsif request.path == login_path
      redirect_to newflow_login_path(request.query_parameters)
    end
  end
end
