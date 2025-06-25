module Legacy
  class SignupController < ApplicationController

    PROFILE_TIMEOUT = 30.minutes

    skip_before_action :authenticate_user!, only: [:profile, :start]

    skip_before_action :complete_signup_profile

    fine_print_skip :general_terms_of_use, :privacy_policy

    before_action :check_ready_for_profile, only: [:profile]

    helper_method :signup_email, :instructor_has_selected_subject

    def start
      redirect_to newflow_signup_path(request.query_parameters)
    end

    def profile
      if request.post?
        handler = case current_user.role
        when "student"
          SignupProfileStudent
        when "instructor"
          SignupProfileInstructor
        else
          SignupProfileOther
        end

        handle_with(handler,
                    contracts_required: !contracts_not_required,
                    client_app: get_client_app,
                    success: lambda do
                      clear_pre_auth_state
                      if current_user.student? || current_user.created_from_signed_data?
                        redirect_back
                      else
                        redirect_to action: :instructor_access_pending
                      end
                    end,
                    failure: lambda do
                      render :profile
                    end)
      else
        params[:profile] = {
          school: current_user.self_reported_school
        }
      end
    end

    def instructor_access_pending
      redirect_back if request.post?
    end

    protected

    def check_ready_for_profile
      # Only expect signed in, needs_profile users, who have a verified email
      fail_signup if !signed_in? ||
                    !current_user.is_needs_profile? ||
                    current_user.contact_infos.verified.none?

      if last_login_is_older_than?(PROFILE_TIMEOUT)
        sign_out!
        redirect_to root_path, alert: t(:"legacy.signup.profile.timeout")
      end

      true
    end

    def fail_signup
      clear_pre_auth_state
      raise SecurityTransgression
    end

    def instructor_has_selected_subject(key)
      params[:profile] && params[:profile][:subjects] && params[:profile][:subjects][key] == '1'
    end

  end
end
