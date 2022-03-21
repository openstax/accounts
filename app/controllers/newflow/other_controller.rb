module Newflow
  class OtherController < BaseController

    before_action :newflow_authenticate_user!, only: :profile_newflow
    before_action :ensure_complete_instructor_signup, only: :profile_newflow
    before_action :prevent_caching, only: :profile_newflow

    def profile_newflow
      render layout: 'application'
    end

    def exit_accounts
      if (redirect_param = extract_params(request.referrer)[:r])
        if Host.trusted?(redirect_param)
          redirect_to(redirect_param)
        else
          raise Lev::SecurityTransgression
        end
      elsif !signed_in? && (redirect_uri = extract_params(stored_url)[:redirect_uri])
        redirect_to(redirect_uri)
      else
        redirect_back # defined in the `action_interceptor` gem
      end
    end

    private

    def ensure_complete_instructor_signup
      return if current_user.student?

      if decorated_user.newflow_edu_incomplete_step_3?
        security_log(:educator_resumed_signup_flow, message: 'User needs to complete SheerID verification. Redirecting.')
        redirect_to(educator_sheerid_form_path)
      elsif decorated_user.newflow_edu_incomplete_step_4?
        security_log(:educator_resumed_signup_flow, message: 'User needs to complete instructor profile. Redirecting.')
        redirect_to(educator_profile_form_path)
      end
    end

  end
end
