module Newflow
  class SignupController < BaseController
    include LoginSignupHelper

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
            @posthog.capture({
              distinct_id: user.uuid,
              event: 'student_verified_email',
              properties: {
                  '$set': { email: user.email_addresses.first.value , name: user.full_name }
              }
            })
            redirect_to signup_done_path
          else
            security_log(:educator_verified_email, {user: user, message: "Educator verified email."})
            @posthog.capture({
              distinct_id: user.uuid,
              event: 'educator_verified_email',
              properties: {
                  '$set': { email: user.email_addresses.first.value , name: user.full_name }
              }
            })
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
      @posthog.capture({
        distinct_id: current_user.uuid,
        event: 'user_completed_signup',
        properties: {
            '$set': { email: current_user.email_addresses.first.value , name: current_user.full_name }
        }
      })
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
        @posthog.capture({
          distinct_id: current_user.uuid,
          event: 'user_redirected_because_signed_in',
          properties: {
              '$set': { email: current_user.email_addresses.first.value , name: current_user.full_name }
          }
        })
        redirect_back(fallback_location: profile_newflow_path(request.query_parameters))
      end
    end
  end
end
