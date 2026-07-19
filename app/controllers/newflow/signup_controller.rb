module Newflow
  class SignupController < BaseController
    include LoginSignupHelper
    include RecaptchaController

    fine_print_skip :general_terms_of_use, :privacy_policy

    before_action(:exit_newflow_signup_if_logged_in, only: :welcome)
    before_action(:newflow_authenticate_user!, only: :signup_done)
    before_action(:skip_signup_done_for_tutor_users, only: :signup_done)

    def welcome
    end

    def verify_email_by_code
      handle_with(
        VerifyEmailByCode,
        success: lambda {
          clear_signup_state
          user = @handler_result.outputs.user
          sign_in!(user)

          if user.student?
            security_log(:student_verified_email, {user: user, message: "Student verified email."})
            log_posthog(user, 'student_verified_email')
            redirect_to signup_done_path
          elsif staff_signup_in_progress?
            security_log(:staff_verified_email, {user: user, message: "Staff verified email."})
            log_posthog(user, 'staff_verified_email')
            redirect_to(staff_details_form_path)
          else
            security_log(:educator_verified_email, {user: user, message: "Educator verified email."})
            log_posthog(user, 'educator_verified_email')
            redirect_to(educator_sheerid_form_path)
          end
        },
        failure: lambda {
          redirect_to(newflow_signup_path)
        }
      )
    end

    def signup_done
      security_log(:user_viewed_signup_form, form_name: action_name)
      log_posthog(current_user, 'user_signup_done')
      @first_name = current_user.first_name
      @email_address = current_user.email_addresses.first&.value
    end

    protected ###############

    def skip_signup_done_for_tutor_users
      return if !current_user.is_tutor_user?

      redirect_back(fallback_location: signup_done_path)
    end

    def exit_newflow_signup_if_logged_in
      if signed_in?
        log_posthog(current_user, 'user_redirected_because_signed_in')
        redirect_back(fallback_location: profile_newflow_path(request.query_parameters))
      end
    end

    # Set by StaffSignupController#staff_signup so the shared "click the link
    # in the confirmation email" path (as opposed to entering the PIN) can
    # route staff users to the staff details step instead of SheerID. Both
    # roles share this action since role isn't distinguishable from the User
    # record alone at this point in signup (role is still :instructor).
    def staff_signup_in_progress?
      session.delete(:staff_signup_in_progress).present?
    end
  end
end
