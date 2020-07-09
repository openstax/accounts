module Newflow
  module EducatorSignupHelper

      def stepwise_signup_flow_triggers
        case action_name
        when 'educator_email_verification_form', 'educator_email_verification_form_updated_email'
          if current_user.activated? && current_user.pending_faculty?
            redirect_to(:educator_sheerid_form)
          elsif current_user.activated? && current_user.confirmed_faculty?
            redirect_to(:educator_profile_form)
          end
        when 'educator_sheerid_form'
          if current_user.confirmed_faculty? || current_user.rejected_faculty?  # || already viewed it
            redirect_to(educator_profile_form_path(request.query_parameters))
          end
        when 'educator_profile_form'
          if is_school_not_supported_by_sheerid? || is_country_not_supported_by_sheerid?
            EducatorSignup::SheeridRejectedEducator.call(user: current_user)
          end
        else
          raise('unexpected action name for stepwise_signup_flow_triggers')
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
