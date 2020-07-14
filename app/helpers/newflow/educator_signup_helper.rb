module Newflow
  module EducatorSignupHelper

      def stepwise_signup_flow_triggers
        case action_name
        when 'educator_email_verification_form', 'educator_email_verification_form_updated_email'
          if unverified_user.activated? && unverified_user.pending_faculty?
            redirect_to(:educator_sheerid_form)
          elsif unverified_user.activated?
            redirect_to(:educator_profile_form)
          end
        when 'educator_sheerid_form'
          if current_incomplete_educator.confirmed_faculty? || current_incomplete_educator.rejected_faculty?
            redirect_to(educator_profile_form_path(request.query_parameters))
          end
        when 'educator_profile_form'
          if is_school_not_supported_by_sheerid? || is_country_not_supported_by_sheerid?
            EducatorSignup::SheeridRejectedEducator.call(user: current_incomplete_educator)
          end
        end
      end

      def is_school_not_supported_by_sheerid?
        params[:school].present?
      end

      def is_country_not_supported_by_sheerid?
        params[:country].present?
      end

  end
end
