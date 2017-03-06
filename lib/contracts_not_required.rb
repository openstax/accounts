module ContractsNotRequired

  def contracts_not_required(client_id: nil)
    @contracts_not_required ||=
      api_call? ||
      arriving_from_app_that_skips_terms?(
        client_id ||
        params[:client_id] ||
        session[:client_id] ||
        get_client_app.try(:uid)
      ) ||
      all_user_apps_skip_terms?
  end

  private

  def api_call?
    json_request?
  end

  def json_request?
    action_controller? ?
      json_action_controller_request? :
      json_rack_request?
  end

  def json_rack_request?
    Mime::Type.lookup(request.env["HTTP_ACCEPT"]).json?
  end

  def json_action_controller_request?
    request.format == :json
  end

  def action_controller?
    request.respond_to?(:format)
  end

  def arriving_from_app_that_skips_terms?(client_id)
    client_id.present? &&
    Doorkeeper::Application.where(uid: client_id).first.try(:skip_terms?)
  end

  def all_user_apps_skip_terms?
    current_user.applications.any? &&
    current_user.applications.all?{|app| app.skip_terms? }
  end

end
