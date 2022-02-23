module Newflow
  class LoginController < BaseController

    include LoginSignupHelper

    GO_TO_STUDENT_SIGNUP = 'student_signup'
    GO_TO_SIGNUP = 'signup'

    fine_print_skip :general_terms_of_use, :privacy_policy, except: :profile_newflow

    before_action :cache_client_app, only: :login_form
    before_action :known_signup_role_redirect, only: :login_form
    before_action :cache_alternate_signup_url, only: :login_form
    before_action :redirect_to_signup_if_go_param_present, only: :login_form
    before_action :redirect_back, if: -> { signed_in? }, only: :login_form

    def login
      handle_with(
        LogInUser,
        success: lambda {
          clear_signup_state
          user = @handler_result.outputs.user

          if user.unverified?
            save_unverified_user(user.id)

            if user.student?
              redirect_to(student_email_verification_form_path)
            else
              redirect_to(educator_email_verification_form_path)
            end

            return
          end

          sign_in!(user, security_log_data: {'email': @handler_result.outputs.email})

          if current_user.student? || !current_user.is_newflow? || (edu_newflow_activated? && decorated_user.can_do?('redirect_back_upon_login'))
            redirect_back # back to `r`edirect parameter. See `before_action :save_redirect`.
          else
            redirect_to(decorated_user.next_step)
          end
        },
        failure: lambda {
          email = @handler_result.outputs.email
          save_login_failed_email(email)

          code = @handler_result.errors.first.code
          case code
          when :cannot_find_user, :multiple_users, :incorrect_password, :too_many_login_attempts
            user = @handler_result.outputs.user
            security_log(:sign_in_failed, { reason: code, email: email })
          end

          render :login_form
        }
      )
    end

    def logout
      sign_out!
      redirect_back(fallback_location: newflow_login_path)
    end

    protected ###############

    def redirect_to_signup_if_go_param_present
      if should_redirect_to_student_signup?
        redirect_to newflow_signup_student_path(request.query_parameters)
      elsif should_redirect_to_signup_welcome?
        redirect_to newflow_signup_path(request.query_parameters)
      end
    end

    def should_redirect_to_student_signup?
      params[:go]&.strip&.downcase == GO_TO_STUDENT_SIGNUP
    end

    def should_redirect_to_signup_welcome?
      params[:go]&.strip&.downcase == GO_TO_SIGNUP
    end

    # Save (in the session) or clear the URL that the "Sign up" button in the FE points to.
    # -- Tutor uses this to send students who want to sign up, back to Tutor which
    # has a message for students just letting them know how to sign up (they must receive an email invitation).
    def cache_alternate_signup_url
      set_alternate_signup_url(params[:signup_at])
    end
  end
end
