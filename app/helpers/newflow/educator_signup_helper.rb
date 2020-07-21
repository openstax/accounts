module Newflow
  module EducatorSignupHelper
    VERIFICATION_ID_URL_PARAM = :verificationid

    def stepwise_signup_flow_triggers
      case action_name
      when 'educator_signup_form'
        redirect_to(educator_email_verification_form_path) if current_incomplete_educator.present?
      when 'educator_email_verification_form', 'educator_email_verification_form_updated_email'
        if current_incomplete_educator.activated? && current_incomplete_educator.pending_faculty?
          redirect_to(educator_sheerid_form_path)
        elsif current_incomplete_educator.activated?
          redirect_to(educator_profile_form_path)
        end
      when 'educator_sheerid_form'
        if current_incomplete_educator.confirmed_faculty? || current_incomplete_educator.rejected_faculty? || current_incomplete_educator.sheerid_verification_id.present?
          redirect_to(educator_profile_form_path(request.query_parameters))
        end
      when 'educator_profile_form'
        if is_school_not_supported_by_sheerid? || is_country_not_supported_by_sheerid?
          EducatorSignup::SheeridRejectedEducator.call(user: current_incomplete_educator)
        elsif sheerid_provided_verification_id_param.present? && current_incomplete_educator.sheerid_verification_id.blank?
          current_incomplete_educator.update_attribute(:sheerid_verification_id, sheerid_provided_verification_id_param)
        end
      end
    end

    def sheerid_provided_verification_id_param
      params[VERIFICATION_ID_URL_PARAM]
    end

    def is_school_not_supported_by_sheerid?
      params[:school].present?
    end

    def is_country_not_supported_by_sheerid?
      params[:country].present?
    end

  end
end
