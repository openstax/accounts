module Newflow
  module EducatorSignupHelper
    VERIFICATION_ID_URL_PARAM = :verificationid

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
