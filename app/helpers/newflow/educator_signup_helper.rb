module Newflow
  module EducatorSignupHelper
    VERIFICATION_ID_URL_PARAM = :verificationid

    def stepwise_signup_flow_triggers
      # if action_name == 'educator_sheerid_form' && (current_user.sheerid_verification_id.present? || current_user.confirmed_faculty? || current_user.rejected_faculty?)
      #   redirect_to(educator_profile_form_path(request.query_parameters)) and return
      # elsif !decorated_user.can_do?(action_name)
      #   redirect_to(decorated_user.next_step)
      # elsif is_school_not_supported_by_sheerid? || is_country_not_supported_by_sheerid?
      #   # EducatorSignup::SheeridRejectedEducator.call(user: current_user)
      #   if verification_id.present? && current_user.sheerid_verification_id.blank?
      #     current_user.sheerid_verification_id = verification_id
      #     current_user.is_educator_pending_cs_verification = true
      #     current_user.save!
      #   end
      # elsif sheerid_provided_verification_id_param.present? && current_user.sheerid_verification_id.blank?
      #   current_user.update_attribute(:sheerid_verification_id, sheerid_provided_verification_id_param)
      # end

      # case action_name
      # when 'educator_signup_form'
      #   redirect_to(educator_email_verification_form_path) if current_user&.activated?
      # when 'educator_email_verification_form', 'educator_email_verification_form_updated_email'
      #   # debugger
      #   if !unverified_user.student? && unverified_user.activated? && unverified_user.pending_faculty?
      #     redirect_to(educator_sheerid_form_path)
      #   elsif unverified_user.activated?
      #     redirect_to(educator_profile_form_path)
      #   end
      # when 'educator_sheerid_form'
      #   debugger
      #   action_name
      #   # if current_user.confirmed_faculty? || current_user.rejected_faculty? || current_user.sheerid_verification_id.present?
      #   #   redirect_to(educator_profile_form_path(request.query_parameters))
      #   # end
      # when 'educator_profile_form'
      #   if is_school_not_supported_by_sheerid? || is_country_not_supported_by_sheerid?
      #     EducatorSignup::SheeridRejectedEducator.call(user: current_user)
      #   elsif sheerid_provided_verification_id_param.present? && current_user.sheerid_verification_id.blank?
      #     current_user.update_attribute(:sheerid_verification_id, sheerid_provided_verification_id_param)
      #   end
      # end
    end

    def decorated_user
      EducatorSignupFlowDecorator.new(current_user, action_name)
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
