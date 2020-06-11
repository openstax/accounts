module Newflow
  class SignupController < BaseController
    include LoginSignupHelper

    fine_print_skip :general_terms_of_use, :privacy_policy

    before_action :restart_signup_if_missing_unverified_user, except: [
      :welcome, :verify_email_by_code, :signup_done
    ]
    before_action :exit_newflow_signup_if_logged_in, only: [
      :welcome, :student_signup_form, :educator_signup_form
    ]

    def verify_email_by_code
      handle_with(
        VerifyEmailByCode,
        success: lambda {
          clear_newflow_state
          user ||= @handler_result.outputs.user
          sign_in!(user)
          security_log(:student_verified_email)

          if user.student?
            redirect_to signup_done_path
          elsif user.instructor?
            redirect_to educator_profile_form_path
          end
        },
        failure: lambda {
          redirect_to(newflow_signup_path)
        }
      )
    end

    def signup_done
      if params[:verificationid]
        redirect_to(session[:after_faculty_verified] || educator_profile_form_path) and return
      end

      @first_name = current_user.first_name
      @email_address = current_user.email_addresses.first&.value
    end

    protected ###############

    def exit_newflow_signup_if_logged_in
      if signed_in?
        redirect_back(fallback_location: profile_newflow_path(request.query_parameters))
      end
    end
  end
end
