module LegacyHelper

  def redirect_to_newflow_if_enabled
    return unless request.get?

    should_redirect_to_newflow = Settings::FeatureFlags.any_newflow_feature_flags? && get_param_to_permit_legacy_flow.blank?

    if should_redirect_to_newflow
      if request.path == signup_path
        redirect_to newflow_signup_path(request.query_parameters)
      else
        redirect_to newflow_login_path(request.query_parameters)
      end
    end
  end

end
