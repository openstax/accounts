module LegacyHelper

  def redirect_to_newflow_if_enabled
    return unless request.get?

    is_student_or_educator_feature_flag_on = Settings::Db.store.student_feature_flag || Settings::Db.store.educator_feature_flag
    should_redirect_to_newflow = is_student_or_educator_feature_flag_on && get_param_permit_legacy_flow.blank?

    if should_redirect_to_newflow
      if request.path == signup_path
        redirect_to newflow_signup_path(request.query_parameters)
      else
        redirect_to newflow_login_path(request.query_parameters)
      end
    end
  end

end
